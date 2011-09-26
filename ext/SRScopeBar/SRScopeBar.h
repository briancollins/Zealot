/* 
 Copyright (c) 2009, Sean Rich
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither Sean Rich nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import <Cocoa/Cocoa.h>
#import "SRScopeBarDataSourceProtocol.h"

#pragma mark -
#pragma mark Constants
extern NSString * const SRScopeBarSelectionDidChangeNotification;
extern NSString * const SROriginalStateKey;
extern NSString * const SRNewStateKey;
extern NSString * const SRClickedObjectKey;
extern NSString * const SRGroupIdentifierKey;

@class SRScopeBarGroup;

#pragma mark -
@interface SRScopeBar : NSControl {
    
@private
    NSView              *accessoryView_;
    NSUInteger          minimumButtonWidth_;
    NSUInteger          minimumPopUpWidth_;
    NSUInteger          intercellSpacing_;
    NSMutableArray      *groups_;
    NSGradient          *backgroundGradient_;
    NSColor             *borderColor_;
    NSColor             *separatorColor_;
    NSColor             *labelColor_;
    NSFormatter         *formatter_;
    NSButtonCell        *buttonCell_;
    NSPopUpButtonCell   *popUpButtonCell_;
    NSPopUpButtonCell   *overflowPullDownCell_;
    NSRect              overflowPullDownRect_;
    BOOL                trackingOverflow_;
    id                  delegate_;
    id<SRScopeBarDataSource> dataSource_;
    BOOL                groupsNeedUpdate_;
    id                  trackingGroup_;
    BOOL                trackingAreasNeedUpdate_;
    BOOL                autoResizesGroups_;
    BOOL                delegateImplementsShouldSelect_;
    BOOL                delegateImplementsShouldCollapse_;
    BOOL                delegateImplementsShouldExpand_;
    BOOL                dataSourceImplementsImageForObject_;
    BOOL                ibInitialized_;
    NSDictionary *textAttributes;
}

@property (assign, nonatomic) IBOutlet id              delegate;
@property (assign, nonatomic) IBOutlet id<SRScopeBarDataSource> dataSource;
@property (retain, nonatomic) NSArray                  *groups;
@property (copy, nonatomic)   NSButtonCell             *buttonCell;
@property (copy, nonatomic)   NSPopUpButtonCell        *popUpButtonCell;
@property (copy, nonatomic)   NSPopUpButtonCell        *overflowPullDownCell;
@property (assign, nonatomic) NSUInteger               minimumButtonWidth;
@property (assign, nonatomic) NSUInteger               minimumPopUpWidth;
@property (assign, nonatomic) NSUInteger               intercellSpacing;
@property (retain, nonatomic) IBOutlet NSView          *accessoryView;
@property (copy, nonatomic)   NSGradient               *backgroundGradient;
@property (retain, nonatomic) NSColor                  *backgroundTopColor;
@property (retain, nonatomic) NSColor                  *backgroundBottomColor;
@property (copy, nonatomic)   NSColor                  *borderColor;
@property (copy, nonatomic)   NSColor                  *separatorColor;
@property (copy, nonatomic)   NSColor                  *labelColor;
@property (assign, nonatomic) BOOL                     autoResizesGroups;

#pragma mark -
#pragma mark Drawing methods

-(void)drawBackground;
-(void)adjustSubviews;
-(NSButtonCell *)preparedButtonCellForGroup:(NSUInteger)groupIndex object:(NSUInteger)objectIndex;
-(NSPopUpButtonCell *)preparedPopUpCellForGroup:(NSUInteger)groupIndex; // menu not assigned

#pragma mark -
#pragma mark Group management methods

-(SRScopeBarGroup *)addGroup;
-(void)addGroup:(SRScopeBarGroup *)group;
-(void)insertGroup:(SRScopeBarGroup *)group atIndex:(NSUInteger)groupIndex;
-(void)removeGroup:(SRScopeBarGroup *)group;
-(void)removeGroupAtIndex:(NSUInteger)groupIndex;

-(NSUInteger)numberOfGroups;
-(SRScopeBarGroup *)groupWithIdentifier:(NSString *)identifier;
-(SRScopeBarGroup *)groupAtIndex:(NSUInteger)groupIndex;
-(NSUInteger)indexOfGroup:(SRScopeBarGroup *)group;
-(void)moveGroupWithIndex:(NSUInteger)originalIndex toIndex:(NSUInteger)destinationIndex;

#pragma mark -
#pragma mark Content management methods

-(void)reloadData;
-(void)reloadDataForGroup:(NSUInteger)groupIndex;

@end



@interface NSObject (SRScopeBarNotifications)
-(void)scopeBarSelectionDidChange:(NSNotification *)notification;
@end

@interface SRScopeBar ()
@property (assign) BOOL ibInitialized;
@end

#pragma mark -
#pragma mark Delegate methods

@interface NSObject (SRScopeBarDelegate)
-(BOOL)scopeBar:(SRScopeBar *)scopeBar shouldSelectObject:(id)object;
-(BOOL)scopeBar:(SRScopeBar *)scopeBar shouldCollapseGroup:(SRScopeBarGroup *)group;
-(BOOL)scopeBar:(SRScopeBar *)scopeBar shouldExpandGroup:(SRScopeBarGroup *)group;
@end
