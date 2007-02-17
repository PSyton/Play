/*
 *  $Id$
 *
 *  Copyright (C) 2006 - 2007 Stephen F. Booth <me@sbooth.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "PlaylistsNode.h"
#import "CollectionManager.h"
#import "PlaylistManager.h"
#import "Playlist.h"
#import "PlaylistNode.h"

@interface PlaylistsNode (Private)
- (void) loadChildren;
@end

@implementation PlaylistsNode

- (id) init
{
	if((self = [super initWithName:NSLocalizedStringFromTable(@"Playlists", @"General", @"")])) {
		[self loadChildren];
		[[[CollectionManager manager] playlistManager] addObserver:self 
														forKeyPath:@"playlists"
														   options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
														   context:nil];
	}
	return self;
}

- (void) dealloc
{
	[[[CollectionManager manager] playlistManager] removeObserver:self forKeyPath:@"playlists"];
	
	[super dealloc];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSArray			*old			= [change valueForKey:NSKeyValueChangeOldKey];
	NSArray			*new			= [change valueForKey:NSKeyValueChangeNewKey];
	int				changeKind		= [[change valueForKey:NSKeyValueChangeKindKey] intValue];
	BOOL			needsSort		= NO;
	NSEnumerator	*enumerator		= nil;
	BrowserNode		*node			= nil;
	Playlist		*playlist		= nil;
	unsigned		i;
	
	NSLog(@"changeKind = %@",[change valueForKey:NSKeyValueChangeKindKey]);
	NSLog(@"old = %@",[change valueForKey:NSKeyValueChangeOldKey]);
	NSLog(@"new = %@",[change valueForKey:NSKeyValueChangeNewKey]);
	
	switch(changeKind) {
		case NSKeyValueChangeInsertion:
			enumerator = [new objectEnumerator];
			while((playlist = [enumerator nextObject])) {
				node = [[PlaylistNode alloc] initWithPlaylist:playlist];
				[self addChild:node];
			}
			break;

		case NSKeyValueChangeRemoval:
			enumerator = [old objectEnumerator];
			while((playlist = [enumerator nextObject])) {
				node = [self findChildWithName:[playlist valueForKey:PlaylistNameKey]];
				if(nil != node) {
					[self removeChild:node];
				}
			}
			break;

		case NSKeyValueChangeSetting:
			for(i = 0; i < [new count]; ++i) {
				playlist = [old objectAtIndex:i];
				node = [self findChildWithName:[playlist valueForKey:PlaylistNameKey]];
				if(nil != node) {
					playlist = [new objectAtIndex:i];
					[node setName:[playlist valueForKey:PlaylistNameKey]];
				}
			}
			break;
			
		case NSKeyValueChangeReplacement:
			NSLog(@"PlaylistsNode REPLACEMENT !! (?)");
			break;
	}
	
	if(needsSort) {
		[self sortChildren];
	}
}

#pragma mark KVC Mutator Overrides

- (void) removeObjectFromChildrenAtIndex:(unsigned)index
{
	BrowserNode *node = [self childAtIndex:index];
	
/*	if([node isPlaying]) {
		[[AudioLibrary library] stop:self];
	}*/
	
	[[node playlist] delete];
	[super removeObjectFromChildrenAtIndex:index];
}

@end

@implementation PlaylistsNode (Private)

- (void) loadChildren
{
	NSArray			*playlists		= [[[CollectionManager manager] playlistManager] playlists];
	NSEnumerator	*enumerator		= [playlists objectEnumerator];
	Playlist		*playlist		= nil;
	PlaylistNode	*node			= nil;
	
	[self willChangeValueForKey:@"children"];
	[_children makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	[_children removeAllObjects];
	while((playlist = [enumerator nextObject])) {
		node = [[PlaylistNode alloc] initWithPlaylist:playlist];
		[node setParent:self];
		[_children addObject:[node autorelease]];
	}
	[self didChangeValueForKey:@"children"];
}

@end
