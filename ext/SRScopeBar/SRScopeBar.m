/* 
 Copyright (c) 2009, Sean Rich
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither Sean Rich nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SRScopeBar.h"
#import "SRScopeBarGroup.h"
#import "SRButtonCell.h"

#pragma mark -
#pragma mark Constants
static NSUInteger SRScopeBarEndPadding;
static NSUInteger SRScopeBarGroupSpacing;
static NSUInteger SRScopeBarOverflowSpacing;
static NSUInteger SRScopeBarAccessorySpacing;
static NSUInteger SRScopeBarGroupSeparatorWidth;
static NSUInteger SRScopeBarGroupSeparatorSpacing;
static NSUInteger SRScopeBarGroupLabelPadding;
static NSUInteger SRScopeBarGroupLabelSpacing;
static NSUInteger SRScopeBarPopUpHeight;
static NSUInteger SRScopeBarPopUpFontSize;
NSString * const SRScopeBarSelectionDidChangeNotification = @"SRScopeBarSelectionDidChangeNotification";
NSString * const SROriginalStateKey = @"SROriginalStateKey";
NSString * const SRNewStateKey = @"SRNewStateKey";
NSString * const SRClickedObjectKey = @"SRClickedObjectKey";
NSString * const SRGroupIdentifierKey = @"SRGroupIdentifierKey";


/* 
 * The SRScopeBarGrouHelper class is a utility helper class for SRScopeBar that encapsulates group-specific data and methods for groups.  The SRScopeBarGroup maintains the
 * data and interface for the group while the SRScopeBarGrouHelper class handles the drawing/event-handling responsbilities of the scope bar for that group
 */
#pragma mark -
@interface SRScopeBarGroupHelper : NSObject {
    SRScopeBar      *scopeBar_;
    SRScopeBarGroup *group_;
    NSRect          frame_;
    NSRect          buttonRect_;
    NSRect          separatorRect_;
    NSRect          labelRect_;
    NSMutableArray  *buttonRects_;
    
    NSButtonCell    *trackingCell_;
    NSInteger       trackingIndex_;
    
    NSUInteger      headerWidth_;
    NSUInteger      maximumWidth_;
    NSUInteger      minimumWidth_;
    NSUInteger      numberOfItemsPeeledOff_;
}

@property (assign, nonatomic) SRScopeBar      *scopeBar;
@property (retain, nonatomic) SRScopeBarGroup *group;
@property (assign, nonatomic) NSUInteger      headerWidth;
@property (assign, nonatomic) NSUInteger      maximumWidth;
@property (assign, nonatomic) NSUInteger      minimumWidth;
@property (assign, nonatomic) NSRect          frame;
@property (assign, nonatomic) NSRect          buttonRect;
@property (assign, nonatomic) NSRect          separatorRect;
@property (assign, nonatomic) NSRect          labelRect;
@property (retain, nonatomic) NSMutableArray  *buttonRects;

#pragma mark Initialization
-(id)initWithGroup:(SRScopeBarGroup *)group inScopeBar:(SRScopeBar *)theScopeBar;

#pragma mark Drawing methods
-(void)drawGroup;

#pragma mark Overflow menu support
-(void)unpeel;
-(NSArray *)peelOffNextItem;
-(BOOL)isPeeled;

#pragma mark Content methods
-(BOOL)usesBindings;
-(void)updateGroupDimensions;

#pragma mark Event handling methods
-(void)mouseEntered:(NSEvent *)theEvent;
-(void)mouseExited:(NSEvent *)theEvent;
-(void)mouseDown:(NSEvent *)theEvent;
-(void)addTrackingAreas;
-(void)popUpMenuItemSelected:(id)sender;

#pragma mark Private methods
-(void)recalculateRects_;
-(void)calculateHeaderWidth_;
-(void)calculateMaximumWidth_;
-(void)calculateMinimumWidth_;
-(NSInteger)maximumButtonWidth_;
-(NSInteger)minimumButtonWidth_;
-(void)updateButtonFrames_;
-(void)setItemsToMaximumWidth_;
-(NSMenuItem *)menuItemForObject_:(NSUInteger)objectIndex;
-(NSMenu *)menu_;
-(void)generatePopUpTrackingCellForEvent_:(NSEvent *)theEvent;
-(void)removeTrackingCell_;

@end

#pragma mark -
@interface SRScopeBar ()
@property (assign, nonatomic) NSRect overflowPullDownRect_;
@property (assign, nonatomic) BOOL groupsNeedUpdate_;
@property (assign, nonatomic) BOOL trackingAreasNeedUpdate_;
@property (assign, nonatomic) BOOL delegateImplementsShouldExpand_;
@property (assign, nonatomic) BOOL delegateImplementsShouldCollapse_;
@end

#pragma mark -
@interface SRScopeBar (SRScopeBarPrivateMethods_)
//-(void)initOverflowCell_;
-(NSButtonCell *)preparedDataSourceCellForGroup_:(NSUInteger)groupIndex object:(NSUInteger)objectIndex;
-(void)resetGroupsToMaxWidth_;
-(void)resetGroupsToZeroWidth_;
-(BOOL)collapseRightMostGroup_;
-(void)peelOffItemsToFitInWidth_:(NSUInteger)width;
-(NSUInteger)countOfUnpeeledGroups_;
-(void)resetOverflowPullDownCell_;
-(void)overflowPullDownItemSelected:(id)sender;
-(SRScopeBarGroupHelper *)groupHelperForGroup_:(SRScopeBarGroup *)theGroup;
-(NSInteger)sumOfMinimumWidthForAllGroups_;
-(NSInteger)sumOfMaximumWidthForAllGroups_;
-(void)resetSelectionForGroup_:(SRScopeBarGroup *)group;
-(SRScopeBarGroup *)groupContainingObject_:(id)object;
@end


#pragma mark -
@implementation SRScopeBarGroupHelper

@synthesize group = group_;
@synthesize scopeBar = scopeBar_;
@synthesize frame = frame_;
@synthesize buttonRect = buttonRect_;
@synthesize separatorRect = separatorRect_;
@synthesize labelRect = labelRect_;
@synthesize buttonRects = buttonRects_;
@synthesize headerWidth = headerWidth_;
@synthesize maximumWidth = maximumWidth_;
@synthesize minimumWidth = minimumWidth_;

#pragma mark -
#pragma mark Initializers

+(void)initialize {
    if (self != [SRScopeBarGroupHelper class])
        return;
    SRScopeBarGroupSeparatorWidth = 1;
    SRScopeBarGroupSeparatorSpacing = 10;
    SRScopeBarGroupLabelPadding = 1;
    SRScopeBarGroupLabelSpacing = 10;
    SRScopeBarPopUpHeight = 17;
    SRScopeBarPopUpFontSize = 12;
}

-(id)init {
    [NSException raise:@"SRScopeBarException" format:@"An instance of an SRScopeBarGroupHelper was initialized using init instead of initWithGroup:inScopeBar:"];
    return nil;
}

-(id)initWithGroup:(SRScopeBarGroup *)group inScopeBar:(SRScopeBar *)theScopeBar {
    if (!(self = [super init]))
        return nil;
    
    [self setScopeBar:theScopeBar];    
    [self setGroup:group];
    [self setButtonRects:[NSMutableArray array]];
    
    trackingIndex_ = -1;
    return self;
}

#pragma mark -
#pragma mark Destructors

-(void)dealloc {
    [trackingCell_ release];
    [super dealloc];
}


#pragma mark -
#pragma mark Accessors

-(void)setFrame:(NSRect)theFrame {
    frame_ = theFrame;
    [self recalculateRects_];
}


#pragma mark -
#pragma mark Drawing methods

-(void)drawGroup {
    if ([[self group] numberOfObjects] == numberOfItemsPeeledOff_)
        return;
    
    // Draw header
    if ([[self group] showsSeparator]) {
        [[[self scopeBar] separatorColor] setFill];
        [NSBezierPath fillRect:[self separatorRect]];
    }
    if ([[self group] showsLabel]) 
        [[[self group] attributedLabel] drawInRect:[self labelRect]];
    
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    
    // Draw pop up button if group is collapsed
    if ([[self group] collapsed]) {
        NSPopUpButtonCell *currentPopUp = trackingCell_ ? (NSPopUpButtonCell *)trackingCell_ : [[self scopeBar] preparedPopUpCellForGroup:groupIndex];
        [currentPopUp drawWithFrame:[self buttonRect] inView:[self scopeBar]];
        return;
    }
    
    // Draw buttons if group isn't collapsed
    for (NSInteger objectIndex = 0; objectIndex < ([[self group] numberOfObjects] - numberOfItemsPeeledOff_); objectIndex++) {
        NSButtonCell *currentCell = (objectIndex == trackingIndex_) ? trackingCell_ : [[self scopeBar] preparedButtonCellForGroup:groupIndex object:objectIndex];
        [currentCell drawWithFrame:[[[self buttonRects] objectAtIndex:objectIndex] rectValue] inView:[self scopeBar]];
    }
}


#pragma mark -
#pragma mark Rect management methods

-(void)updateGroupDimensions {
    [self calculateHeaderWidth_];
    [self calculateMaximumWidth_];
    [self calculateMinimumWidth_];
}

-(void)calculateHeaderWidth_ {
    NSUInteger headerWidth = 0;
    if ([[self group] showsLabel])
        headerWidth += [[[self group] attributedLabel] size].width + SRScopeBarGroupLabelPadding + SRScopeBarGroupLabelSpacing;
    if ([[self group] showsSeparator])
        headerWidth += SRScopeBarGroupSeparatorWidth + SRScopeBarGroupSeparatorSpacing;
    [self setHeaderWidth:headerWidth];
}

-(void)calculateMaximumWidth_ {
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    if (groupIndex == NSNotFound) {
        [self setMaximumWidth:0];
        return;
    }
    
    if (numberOfItemsPeeledOff_ == [[self group] numberOfObjects]) {
        [self setMaximumWidth:0];
        return;
    }
    
    if (![[self group] collapsed]) {
        [self setMaximumWidth:([self maximumButtonWidth_] + [self headerWidth])];
        return;
    }
    
    NSPopUpButtonCell *popUpCell = [[self scopeBar] preparedPopUpCellForGroup:groupIndex];
    [self setMaximumWidth:([self headerWidth] + [popUpCell cellSize].width)];
}

-(NSInteger)maximumButtonWidth_ {
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    NSInteger totalMaximumWidth = 0;
    for (NSUInteger objectIndex = 0; objectIndex < ([[self group] numberOfObjects] - numberOfItemsPeeledOff_); objectIndex++) {
        NSButtonCell *buttonCell = [[self scopeBar] preparedButtonCellForGroup:groupIndex object:objectIndex];
        totalMaximumWidth += ([buttonCell cellSize].width + [[self scopeBar] intercellSpacing]);
    }
    
    if (([[self group] numberOfObjects] - numberOfItemsPeeledOff_) != 0)
        totalMaximumWidth -= [[self scopeBar] intercellSpacing];
    
    return totalMaximumWidth;
}

-(void)calculateMinimumWidth_ {
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    if (groupIndex == NSNotFound) {
        [self setMinimumWidth:0];
        return;
    }
    
    if (numberOfItemsPeeledOff_ == [[self group] numberOfObjects]) {
        [self setMinimumWidth:0];
        return;
    }
    
    if (![[self group] collapsed]) {
        [self setMinimumWidth:([self minimumButtonWidth_] + [self headerWidth])];
        return;
    }
    
    NSPopUpButtonCell *popUpCell = [[self scopeBar] preparedPopUpCellForGroup:groupIndex];
    NSInteger minPopUpWidth = [popUpCell cellSize].width;
    if ([[self scopeBar] minimumPopUpWidth] < minPopUpWidth)
        minPopUpWidth = [[self scopeBar] minimumPopUpWidth];
    [self setMinimumWidth:([self headerWidth] + minPopUpWidth)];
}

-(NSInteger)minimumButtonWidth_ {
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    NSInteger totalMinimumWidth = 0;
    NSInteger scopeBarMinimumButtonWidth = [[self scopeBar] minimumButtonWidth];
    for (NSUInteger objectIndex = 0; objectIndex < ([[self group] numberOfObjects] - numberOfItemsPeeledOff_); objectIndex++) {
        NSButtonCell *buttonCell = [[self scopeBar] preparedButtonCellForGroup:groupIndex object:objectIndex];
        NSInteger minimumButtonWidth = [buttonCell cellSize].width;
        if (scopeBarMinimumButtonWidth < minimumButtonWidth)
            minimumButtonWidth = scopeBarMinimumButtonWidth;
        totalMinimumWidth += minimumButtonWidth + [[self scopeBar] intercellSpacing];
    }
    if (([[self group] numberOfObjects] - numberOfItemsPeeledOff_) != 0)
        totalMinimumWidth -= [[self scopeBar] intercellSpacing];
    return totalMinimumWidth;
}


#pragma mark -
#pragma mark Menu support

-(void)unpeel {
    numberOfItemsPeeledOff_ = 0;
}

-(NSArray *)peelOffNextItem {
    if (numberOfItemsPeeledOff_ == [[self group] numberOfObjects])
        return nil;
    NSMutableArray *menuItemArray = [NSMutableArray array];
    if (![[self group] collapsed]) {
        NSInteger objectIndex = [[self group] numberOfObjects] - numberOfItemsPeeledOff_++ - 1;
        [self updateGroupDimensions];
        [menuItemArray addObject:[self menuItemForObject_:objectIndex]];
        return menuItemArray;
    }
    numberOfItemsPeeledOff_ = [[self group] numberOfObjects];
    [self updateGroupDimensions];
    for (NSUInteger objectIndex = 0; objectIndex < [[self group] numberOfObjects]; objectIndex++) 
        [menuItemArray addObject:[self menuItemForObject_:objectIndex]];
    return menuItemArray;
}

-(BOOL)isPeeled {
    if (numberOfItemsPeeledOff_ == [[self group] numberOfObjects])
        return YES;
    return NO;
}

-(NSMenuItem *)menuItemForObject_:(NSUInteger)objectIndex {
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    if (groupIndex == NSNotFound) 
        return nil;
    
    NSButtonCell *buttonCell = [[self scopeBar] preparedButtonCellForGroup:groupIndex object:objectIndex];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[buttonCell title] action:NULL keyEquivalent:@""];
    [menuItem setImage:[buttonCell image]];
    NSIndexSet *selectionIndexes = [[self group] selectionIndexes];
    [menuItem setState:([selectionIndexes containsIndex:objectIndex] ? NSOnState : NSOffState)];
    [menuItem setRepresentedObject:[[self group] objectAtIndex:objectIndex]];
    return [menuItem autorelease];
}

-(NSMenu *)menu_ {
    NSMenu *groupMenu = [[NSMenu alloc] initWithTitle:@""];
    for (NSUInteger objectIndex = 0; objectIndex < [[self group] numberOfObjects]; objectIndex++) {
        [groupMenu addItem:[self menuItemForObject_:objectIndex]];
    }
    return [groupMenu autorelease];
}


#pragma mark -
#pragma mark Content methods

-(BOOL)usesBindings {
    return ([[self group] infoForBinding:NSContentBinding] != nil);
}


#pragma mark -
#pragma mark Event handling methods

-(void)mouseEntered:(NSEvent *)theEvent {
    NSPoint eventPoint = [[self scopeBar] convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect eventRect = NSMakeRect(buttonRect_.origin.x, [self frame].origin.y, buttonRect_.size.width, [self frame].size.height);
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    if ([[self group] collapsed] && [[self scopeBar] mouse:eventPoint inRect:eventRect]) {
        [self generatePopUpTrackingCellForEvent_:theEvent];
        [[self scopeBar] setNeedsDisplay:YES];
        return;
    }
    
    for (NSUInteger objectIndex = 0; objectIndex < [[self group] numberOfObjects]; objectIndex++) {
        NSRect objectRect = [[[self buttonRects] objectAtIndex:objectIndex] rectValue];
        objectRect.origin.y = eventRect.origin.y;
        objectRect.size.height = eventRect.size.height;
        if (![[self scopeBar] mouse:eventPoint inRect:objectRect])
            continue;
        trackingCell_ = [[[self scopeBar] preparedButtonCellForGroup:groupIndex object:objectIndex] retain];
        trackingIndex_ = objectIndex;
        [trackingCell_ mouseEntered:theEvent];
        [[self scopeBar] setNeedsDisplay:YES];
        return;
    }
}

-(void)mouseExited:(NSEvent *)theEvent {
    [self removeTrackingCell_];
    [[self scopeBar] setNeedsDisplay:YES];    
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (!trackingCell_)
        return;
    
    if ([[self group] collapsed]) {
        [(NSPopUpButtonCell *)trackingCell_ setMenu:[self menu_]];
        [(NSPopUpButtonCell *)trackingCell_ performClickWithFrame:[self buttonRect] inView:[self scopeBar]]; 
        return;
    }
    
    
    id object = [[[self group] objectAtIndex:trackingIndex_] retain];
    BOOL delegateImplementsShouldSelectObject = [[[self scopeBar] delegate] respondsToSelector:@selector(scopeBar:shouldSelectObject:)];
    if (delegateImplementsShouldSelectObject && ![[[self scopeBar] delegate] scopeBar:[self scopeBar] shouldSelectObject:object]) {
        [object release];
        return;
    }
    
    NSPoint eventPoint;
    NSRect buttonRect = [[[self buttonRects] objectAtIndex:trackingIndex_] rectValue];
    while ([theEvent type] != NSLeftMouseUp) {
        eventPoint = [[self scopeBar] convertPoint:[theEvent locationInWindow] fromView:nil];
        BOOL mouseInButton = [[self scopeBar] mouse:eventPoint inRect:buttonRect];
        [trackingCell_ setHighlighted:mouseInButton];
        [[self scopeBar] setNeedsDisplay:YES];
        theEvent = [[[self scopeBar] window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask)];
    }
    
    [trackingCell_ setHighlighted:NO];
    eventPoint = [[self scopeBar] convertPoint:[theEvent locationInWindow] fromView:nil];
    if ([[self scopeBar] mouse:eventPoint inRect:buttonRect]) {
        [[self group] didClickObject:trackingIndex_];
        NSCellStateValue newState = [[[self group] selectionIndexes] containsIndex:trackingIndex_] ? NSOnState : NSOffState;
        [trackingCell_ setState:newState];
    }
    [[self scopeBar] setNeedsDisplay:YES];
    [object release];
}

-(void)addTrackingAreas {
    NSUInteger objectCount = [[self group] numberOfObjects];
    if (objectCount == 0)
        return;
    
    if ([[self group] collapsed] && objectCount != numberOfItemsPeeledOff_) {
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:buttonRect_ options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:[self scopeBar] userInfo:nil];
        [[self scopeBar] addTrackingArea:trackingArea];
        [trackingArea release];
        return;
    }
    
    for (NSUInteger objectIndex = 0; objectIndex < (objectCount - numberOfItemsPeeledOff_); objectIndex++) {
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[[buttonRects_ objectAtIndex:objectIndex] rectValue] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:[self scopeBar] userInfo:nil];
        [[self scopeBar] addTrackingArea:trackingArea];
        [trackingArea release];
    }
}

-(void)popUpMenuItemSelected:(id)sender {
    id selectedObject = [[[(NSPopUpButtonCell *)trackingCell_ selectedItem] representedObject] retain];
    
    // Give the delegate a chance to refuse the selection
    BOOL delegateImplementsShouldSelectObject = [[[self scopeBar] delegate] respondsToSelector:@selector(scopeBar:shouldSelectObject:)];
    if (delegateImplementsShouldSelectObject && ![[[self scopeBar] delegate] scopeBar:[self scopeBar] shouldSelectObject:selectedObject]) {
        [selectedObject release];
        
        // Reset the tracking cell
        [self removeTrackingCell_];
        NSPoint windowMouseLocation = [[[self scopeBar] window] convertScreenToBase:[NSEvent mouseLocation]];
        NSPoint viewMouseLocation = [[self scopeBar] convertPoint:windowMouseLocation fromView:nil];
        if ([[self scopeBar] mouse:viewMouseLocation inRect:[self buttonRect]]) 
            [self generatePopUpTrackingCellForEvent_:nil];
        return;
    }
    
    // Update selection state
    [[self group] didClickObject:[(NSPopUpButtonCell *)trackingCell_ indexOfSelectedItem]];
    [[self scopeBar] adjustSubviews];
        
    // Popup's title and state have likely changed, so regenerate it
    [self removeTrackingCell_];
    NSPoint windowMouseLocation = [[[self scopeBar] window] convertScreenToBase:[NSEvent mouseLocation]];
    NSPoint viewMouseLocation = [[self scopeBar] convertPoint:windowMouseLocation fromView:nil];
    if ([[self scopeBar] mouse:viewMouseLocation inRect:[self buttonRect]])
        [self generatePopUpTrackingCellForEvent_:nil];
    
    [selectedObject release];
}

-(void)generatePopUpTrackingCellForEvent_:(NSEvent *)theEvent {
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    trackingCell_ = [[[self scopeBar] preparedPopUpCellForGroup:groupIndex] retain];
    [trackingCell_ setTarget:self];
    [trackingCell_ mouseEntered:theEvent];    
}

-(void)removeTrackingCell_ {
    [trackingCell_ release];
    trackingCell_ = nil;
    trackingIndex_ = -1;
}


#pragma mark -
#pragma mark Private utility methods

-(void)recalculateRects_ {
    if ([[self group] numberOfObjects] == 0) 
        return;
    
    buttonRect_ = [self frame];
    
    if ([[self group] showsSeparator]) {
        NSDivideRect(buttonRect_, &separatorRect_, &buttonRect_, SRScopeBarGroupSeparatorWidth, NSMinXEdge);
        separatorRect_ = NSInsetRect(separatorRect_, 0, (buttonRect_.size.height * 0.18));        
        if (buttonRect_.size.width >= SRScopeBarGroupSeparatorSpacing) {
            buttonRect_.origin.x += SRScopeBarGroupSeparatorSpacing;
            buttonRect_.size.width -= SRScopeBarGroupSeparatorSpacing;
        }
    }
    else
        separatorRect_ = NSZeroRect;
    
    if ([[self group] showsLabel]) {
        NSAttributedString *attributedLabel = [[self group] attributedLabel];
        NSInteger labelWidth = [attributedLabel size].width + SRScopeBarGroupLabelPadding;
        NSDivideRect(buttonRect_, &labelRect_, &buttonRect_, labelWidth, NSMinXEdge);
        labelRect_ = NSInsetRect(labelRect_, 0, ((NSHeight(labelRect_) - [attributedLabel size].height) / 2));
        labelRect_.origin.y += [[self scopeBar] isFlipped] ? -1 : 1;
        if (buttonRect_.size.width >= SRScopeBarGroupLabelSpacing) {
            buttonRect_.origin.x += SRScopeBarGroupLabelSpacing;
            buttonRect_.size.width -= SRScopeBarGroupLabelSpacing;
        }
    }
    else
        labelRect_ = NSZeroRect;
    
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    CGFloat height = [[[self scopeBar] preparedButtonCellForGroup:groupIndex object:0] cellSize].height;
    CGFloat deltaY = (buttonRect_.size.height - height) / 2;
    buttonRect_ = NSInsetRect(buttonRect_, 0, deltaY);
    if (![[self group] collapsed])
        [self updateButtonFrames_];
}

-(void)updateButtonFrames_ {    
    if ([[self group] collapsed]) {
        return;
    }
    
    NSUInteger numberOfObjects = [[self group] numberOfObjects];
    if (numberOfObjects == 0)
        return;
    
    [[self buttonRects] removeAllObjects];
    // If there's plenty of room, then set all items to maximum width
    if ([self maximumWidth] <= [self frame].size.width) {
        [self setItemsToMaximumWidth_];
        return;
    }
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    NSInteger totalWidthDelta = [self maximumWidth] - [self minimumWidth];
    NSInteger totalWidthAdjustment = [self maximumWidth] - [self headerWidth] - buttonRect_.size.width;
    NSInteger objectWidthAdjustment = 0;
    NSInteger widthAdjustmentRemaining = totalWidthAdjustment;
    NSInteger xPosition = buttonRect_.origin.x;
    NSInteger scopeBarMinimumButtonWidth = [[self scopeBar] minimumButtonWidth];
    for (NSUInteger objectIndex = 0; objectIndex < (numberOfObjects - numberOfItemsPeeledOff_); objectIndex++) {
        NSButtonCell *buttonCell = [[self scopeBar] preparedButtonCellForGroup:groupIndex object:objectIndex];
        NSInteger objectMinWidth = [buttonCell cellSize].width;
        if (scopeBarMinimumButtonWidth < objectMinWidth)
            objectMinWidth = scopeBarMinimumButtonWidth;
        NSInteger objectWidthDelta = [buttonCell cellSize].width - objectMinWidth;
        if (objectIndex == (numberOfObjects - numberOfItemsPeeledOff_))
            objectWidthAdjustment = widthAdjustmentRemaining;
        else {
            objectWidthAdjustment = floor((CGFloat)objectWidthDelta / (CGFloat)totalWidthDelta * (CGFloat)totalWidthAdjustment);
            widthAdjustmentRemaining -= objectWidthAdjustment;
        }
        NSRect buttonFrame = NSMakeRect(xPosition, [self buttonRect].origin.y, ([buttonCell cellSize].width - objectWidthAdjustment), [self buttonRect].size.height);
        [[self buttonRects] addObject:[NSValue valueWithRect:buttonFrame]];
        xPosition += (buttonFrame.size.width + [[self scopeBar] intercellSpacing]);
    }    
}

-(void)setItemsToMaximumWidth_ {
    NSInteger xPosition = [self buttonRect].origin.x;
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:[self group]];
    [[self buttonRects] removeAllObjects];
    for (NSUInteger objectIndex = 0; objectIndex < ([[self group] numberOfObjects] - numberOfItemsPeeledOff_); objectIndex++) {
        NSButtonCell *buttonCell = [[self scopeBar] preparedButtonCellForGroup:groupIndex object:objectIndex];
        NSRect objectRect = NSMakeRect(xPosition, buttonRect_.origin.y, [buttonCell cellSize].width, buttonRect_.size.height);
        [[self buttonRects] addObject:[NSValue valueWithRect:objectRect]];
        xPosition += objectRect.size.width + [[self scopeBar] intercellSpacing];
    }
}

@end


#pragma mark -
@interface SROverflowPullDownCell : NSPopUpButtonCell
@end

@implementation SROverflowPullDownCell

-(id)initTextCell:(NSString *)stringValue pullsDown:(BOOL)pullDown {
    if (!(self = [super initTextCell:stringValue pullsDown:YES]))
        return nil;
    
    [self setButtonType:NSPushOnPushOffButton];
    [self setArrowPosition:NSPopUpNoArrow];
    [self setControlSize:NSSmallControlSize];
    [self setImagePosition:NSImageOnly];
    [self setBordered:NO];
    [self setHighlightsBy:NSChangeGrayCellMask];
    
    return self;
}

-(NSSize)cellSize {
    NSMenu *cellMenu = [self menu];
    if (!cellMenu || [cellMenu numberOfItems] == 0)
        return NSZeroSize;
    
    // Cell size of the overflow button is based on the image
    NSMenuItem *firstItem = [cellMenu itemAtIndex:0];
    if (![firstItem image])
        return NSZeroSize;
    
    NSSize imageSize = [[firstItem image] size];
    // Add in padding, otherwise the image gets clipped
    imageSize.width += 12;
    return imageSize;
}

@end


#pragma mark -
@implementation SRScopeBar

@synthesize delegate = delegate_;
@synthesize dataSource = dataSource_;
@synthesize buttonCell = buttonCell_;
@synthesize popUpButtonCell = popUpButtonCell_;
@synthesize overflowPullDownCell = overflowPullDownCell_;
@synthesize minimumButtonWidth = minimumButtonWidth_;
@synthesize minimumPopUpWidth = minimumPopUpWidth_;
@synthesize intercellSpacing = intercellSpacing_;
@synthesize accessoryView = accessoryView_;
@synthesize backgroundGradient = backgroundGradient_;
@synthesize borderColor = borderColor_;
@synthesize separatorColor = separatorColor_;
@synthesize labelColor = labelColor_;
@synthesize autoResizesGroups = autoResizesGroups_;
@synthesize overflowPullDownRect_;
@synthesize groupsNeedUpdate_;
@synthesize trackingAreasNeedUpdate_;
@synthesize delegateImplementsShouldExpand_;
@synthesize delegateImplementsShouldCollapse_;
@synthesize ibInitialized = ibInitialized_;

#pragma mark -
#pragma mark Initialization

+(void)initialize {
    if (self != [SRScopeBar class])
        return;
    
    CGFloat smallFontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
    SRScopeBarEndPadding = smallFontSize;
    SRScopeBarGroupSpacing = smallFontSize;
    SRScopeBarOverflowSpacing = 5;
    SRScopeBarAccessorySpacing = smallFontSize;
    [self setKeys:[NSArray arrayWithObjects:@"groups", nil] triggerChangeNotificationsForDependentKey:@"numberOfGroups"];
}

-(id)initWithFrame:(NSRect)frame {
    if (!(self = [super initWithFrame:frame]))
        return nil;
    
    [self setMinimumButtonWidth:70];
    [self setMinimumPopUpWidth:70];
    [self setAutoResizesGroups:YES];
    [self setIntercellSpacing:5];
    
    NSColor *scopeBarGradientTopColor = [NSColor colorWithCalibratedWhite:0.94 alpha:1.0];
    NSColor *scopeBarGradientBottomColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
    NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:scopeBarGradientBottomColor endingColor:scopeBarGradientTopColor];
    [self setBackgroundGradient:backgroundGradient];
    [backgroundGradient autorelease];
    [self setBorderColor:[NSColor colorWithCalibratedWhite:0.6 alpha:1.0]];
    [self setSeparatorColor:[NSColor colorWithCalibratedWhite:0.46 alpha:1.0]];
    [self setLabelColor:[NSColor colorWithCalibratedWhite:0.46 alpha:1.0]];
    
    SRButtonCell *buttonCell = [[SRButtonCell alloc] initTextCell:@""];
    [buttonCell setBezelStyle:NSRecessedBezelStyle];
    [buttonCell setButtonType:NSPushOnPushOffButton];
    [buttonCell setControlSize:NSSmallControlSize];
    [buttonCell setFont:[NSFont boldSystemFontOfSize:12]];
    [buttonCell setShowsBorderOnlyWhileMouseInside:YES];
    [buttonCell setLineBreakMode:NSLineBreakByTruncatingTail];
    [buttonCell setState:NSOffState]; 
    [buttonCell setImagePosition:NSImageLeft];
    [self setButtonCell:buttonCell];
    [buttonCell autorelease];
    
    NSPopUpButtonCell *popUpCell = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
    [popUpCell setBezelStyle:NSRecessedBezelStyle];
    [popUpCell setButtonType:NSPushOnPushOffButton];
    [popUpCell setArrowPosition:NSPopUpArrowAtBottom];
    [popUpCell setControlSize:NSSmallControlSize];
    [popUpCell setFont:[NSFont boldSystemFontOfSize:12]];
    [popUpCell setShowsBorderOnlyWhileMouseInside:YES];
    [popUpCell setLineBreakMode:NSLineBreakByTruncatingTail];
    [popUpCell setImagePosition:NSImageLeft];
    [self setPopUpButtonCell:popUpCell];
    [popUpCell autorelease];
    
    SROverflowPullDownCell *pullDownCell = [[SROverflowPullDownCell alloc] initTextCell:@"" pullsDown:YES];
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    [menu setAutoenablesItems:NO];
    NSMenuItem *pullDownMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    NSString *imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"overflowImage" ofType:@"tiff"];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
    [pullDownMenuItem setImage:image];
    [image release];
    [menu addItem:pullDownMenuItem];
    [pullDownCell setMenu:menu];
    [self setOverflowPullDownCell:pullDownCell];
    
    [pullDownMenuItem release];
    [menu release];
    [pullDownCell release];
      
    return self;
}

-(id)initWithCoder:(NSCoder *)coder {
    if (![coder allowsKeyedCoding])
        return nil;
    
    if (!(self = [super initWithCoder:coder]))
        return nil;
    
    [self setDelegate:[coder decodeObjectForKey:@"SRScopeBar delegate"]];
    [self setDataSource:[coder decodeObjectForKey:@"SRScopeBar dataSource"]];
    [self setGroups:[coder decodeObjectForKey:@"SRScopeBar groups"]];
    [self setButtonCell:[coder decodeObjectForKey:@"SRScopeBar buttonCell"]];
    [self setPopUpButtonCell:[coder decodeObjectForKey:@"SRScopeBar popUpButtonCell"]];
    [self setOverflowPullDownCell:[coder decodeObjectForKey:@"SRScopeBar overfloPullDownCell"]];
    [self setMinimumButtonWidth:[[coder decodeObjectForKey:@"SRScopeBar minimumButtonWidth"] unsignedIntegerValue]];
    [self setMinimumPopUpWidth:[[coder decodeObjectForKey:@"SRScopeBar minimumPopUpWidth"] unsignedIntegerValue]];
    [self setIntercellSpacing:[[coder decodeObjectForKey:@"SRScopeBar intercellSpacing"] unsignedIntegerValue]];
    [self setFormatter:[coder decodeObjectForKey:@"SRScopeBar formatter"]];
    [self setAccessoryView:[coder decodeObjectForKey:@"SRScopeBar accessoryView"]];
    [self setBackgroundGradient:[coder decodeObjectForKey:@"SRScopeBar backgroundGradient"]];
    [self setBorderColor:[coder decodeObjectForKey:@"SRScopeBar borderColor"]];
    [self setSeparatorColor:[coder decodeObjectForKey:@"SRScopeBar separatorColor"]];
    [self setLabelColor:[coder decodeObjectForKey:@"SRScopeBar labelColor"]];
    [self setAutoResizesGroups:[[coder decodeObjectForKey:@"SRScopeBar autoResizesGroups"] boolValue]];
    ibInitialized_ = [[coder decodeObjectForKey:@"SRScopeBar ibInitialized"] boolValue];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    if (![coder allowsKeyedCoding])
        return;
    
    [super encodeWithCoder:coder];
    [coder encodeConditionalObject:[self delegate] forKey:@"SRScopeBarGroup delegate"];
    [coder encodeConditionalObject:[self dataSource] forKey:@"SRScopeBar dataSource"];
    [coder encodeObject:[self groups] forKey:@"SRScopeBar groups"];
    [coder encodeObject:[self buttonCell] forKey:@"SRScopeBar buttonCell"];
    [coder encodeObject:[self popUpButtonCell] forKey:@"SRScopeBar popUpButtonCell"];
    [coder encodeObject:[self overflowPullDownCell] forKey:@"SRScopeBar overfloPullDownCell"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:[self minimumButtonWidth]] forKey:@"SRScopeBar minimumButtonWidth"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:[self minimumPopUpWidth]] forKey:@"SRScopeBar minimumPopUpWidth"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:[self intercellSpacing]] forKey:@"SRScopeBar intercellSpacing"];
    [coder encodeObject:[self accessoryView] forKey:@"SRScopeBar accessoryView"];
    [coder encodeObject:[self backgroundGradient] forKey:@"SRScopeBar backgroundGradient"];
    [coder encodeObject:[self borderColor] forKey:@"SRScopeBar borderColor"];
    [coder encodeObject:[self separatorColor] forKey:@"SRScopeBar separatorColor"];
    [coder encodeObject:[self labelColor] forKey:@"SRScopeBar labelColor"];
    [coder encodeObject:[NSNumber numberWithBool:[self autoResizesGroups]] forKey:@"SRScopeBar autoResizesGroups"];
    [coder encodeObject:[self formatter] forKey:@"SRScopeBar formatter"];
    [coder encodeObject:[NSNumber numberWithBool:ibInitialized_] forKey:@"SRScopeBar ibInitialized"];
}


#pragma mark -
#pragma mark Destructors

-(void)dealloc {
    [accessoryView_ release];
    [formatter_ release];
    [groups_ release];
    [backgroundGradient_ release];
    [borderColor_ release];
    [separatorColor_ release];
    [labelColor_ release];
    [buttonCell_ release];
    [popUpButtonCell_ release];
    [overflowPullDownCell_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors

-(void)setDelegate:(id)theDelegate {
    if (delegate_ == theDelegate)
        return;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    if (delegate_)
        [notificationCenter removeObserver:delegate_ name:SRScopeBarSelectionDidChangeNotification object:nil];
    
    delegate_ = theDelegate;
    
    if ([delegate_ respondsToSelector:@selector(scopeBarSelectionDidChange:)])
        [notificationCenter addObserver:delegate_ selector:@selector(scopeBarSelectionDidChange:) name:SRScopeBarSelectionDidChangeNotification object:nil];
    delegateImplementsShouldSelect_ = [delegate_ respondsToSelector:@selector(scopeBar:shouldSelectObject:)] ? YES : NO;
    delegateImplementsShouldCollapse_ = [delegate_ respondsToSelector:@selector(scopeBar:shouldCollapseGroup:)] ? YES : NO;
    delegateImplementsShouldExpand_ = [delegate_ respondsToSelector:@selector(scopeBar:shouldExpandGroup:)] ? YES : NO;
}

-(void)setDataSource:(id<SRScopeBarDataSource>) theDataSource {
    dataSource_ = theDataSource;
    dataSourceImplementsImageForObject_ = [dataSource_ respondsToSelector:@selector(scopeBar:imageForObjectInGroup:atIndex:)] ? YES : NO;
}

-(NSArray *)groups {
    return [groups_ valueForKeyPath:@"group"];
}

-(void)setGroups:(NSArray *)groupsArray {
    if ([self groups] == groupsArray)
        return;
    
    [self willChangeValueForKey:@"groups"];
    [groups_ removeAllObjects];
    [self didChangeValueForKey:@"groups"];
    for (SRScopeBarGroup *group in groupsArray) {
        if (![group isKindOfClass:[SRScopeBarGroup class]]) {
            NSException *invalidArgumentException = [NSException exceptionWithName:NSInvalidArgumentException reason:@"SRScopeBar:setGroups: element in array not of class SRScopeBarGroup" userInfo:nil];
            @throw invalidArgumentException;
        }
        [self addGroup:group];
    }
}

-(NSButtonCell *)buttonCell {
    return [[buttonCell_ copy] autorelease];
}

-(void)setButtonCell:(NSButtonCell *)theButtonCell {
    if (buttonCell_ == theButtonCell)
        return;
    
    [buttonCell_ release];
    buttonCell_ = [theButtonCell copy];
    [self adjustSubviews];
}

-(NSPopUpButtonCell *)popUpButtonCell {
    return [[popUpButtonCell_ copy] autorelease];
}

-(void)setPopUpButtonCell:(NSPopUpButtonCell *)thePopUpCell {
    if (popUpButtonCell_ == thePopUpCell)
        return;
    
    [popUpButtonCell_ release];
    popUpButtonCell_ = [thePopUpCell copy];
    [popUpButtonCell_ setUsesItemFromMenu:NO];
    [popUpButtonCell_ setAltersStateOfSelectedItem:NO];
    [popUpButtonCell_ setAction:@selector(popUpMenuItemSelected:)];    
    [popUpButtonCell_ setAutoenablesItems:NO];
    [self adjustSubviews];
}

-(void)setOverflowPullDownCell:(NSPopUpButtonCell *)thePullDownCell {
    if (overflowPullDownCell_ == thePullDownCell)
        return;
    
    [overflowPullDownCell_ release];
    overflowPullDownCell_ = [thePullDownCell copy];
    [overflowPullDownCell_ setTarget:self];
    [overflowPullDownCell_ setAction:@selector(overflowPullDownItemSelected:)];
    [overflowPullDownCell_ setAutoenablesItems:NO];
    [overflowPullDownCell_ setAltersStateOfSelectedItem:NO];
    [overflowPullDownCell_ setUsesItemFromMenu:YES];
    [self adjustSubviews];
}

-(void)setAccessoryView:(NSView *)theView {
    if (accessoryView_ == theView)
        return;
    
    [accessoryView_ release];
    accessoryView_ = [theView retain];
    [self addSubview:accessoryView_];   
    [self adjustSubviews];
}

-(void)setMinimumButtonWidth:(NSUInteger)width {
    minimumButtonWidth_ = width;
    [self reloadData];
}

-(void)setMinimumPopUpWidth:(NSUInteger)width {
    minimumPopUpWidth_ = width;
    [self reloadData];
}

-(void)setIntercellSpacing:(NSUInteger)spacing {
    intercellSpacing_ = spacing;
    [self reloadData];
}

-(NSFormatter *)formatter {
    return formatter_;
}

-(void)setFormatter:(NSFormatter *)theFormatter {
    if (formatter_ == theFormatter)
        return;
    [formatter_ release];
    formatter_ = [theFormatter retain];
    [self reloadData];
}

-(void)setBackgroundGradient:(NSGradient *)theGradient {
    if (backgroundGradient_ == theGradient)
        return;
    [backgroundGradient_ release];
    backgroundGradient_ = [theGradient copy];
    [self adjustSubviews];
}

-(NSColor *)backgroundTopColor {
    return [[self backgroundGradient] interpolatedColorAtLocation:1.0];
}

-(void)setBackgroundTopColor:(NSColor *)topColor {
    NSColor *bottomColor = [[self backgroundGradient] interpolatedColorAtLocation:0.0];
    NSGradient *newGradient = [[NSGradient alloc] initWithStartingColor:bottomColor endingColor:topColor];
    [backgroundGradient_ release];
    backgroundGradient_ = newGradient;
    [self adjustSubviews];
}

-(NSColor *)backgroundBottomColor {
    return [[self backgroundGradient] interpolatedColorAtLocation:.0];
}

-(void)setBackgroundBottomColor:(NSColor *)bottomColor {
    NSColor *topColor = [[self backgroundGradient] interpolatedColorAtLocation:1.0];
    NSGradient *newGradient = [[NSGradient alloc] initWithStartingColor:bottomColor endingColor:topColor];
    [backgroundGradient_ release];
    backgroundGradient_ = newGradient;
    [self adjustSubviews];
}


#pragma mark -
#pragma mark Drawing methods

-(void)drawRect:(NSRect)dirtyRect {
    if ([self groupsNeedUpdate_]) 
        [self calcSize];
    
    [self drawBackground];
    for (SRScopeBarGroupHelper *groupHelper in groups_)
        [groupHelper drawGroup];
    
    if ([[self overflowPullDownCell] numberOfItems] > 1)
        [[self overflowPullDownCell] drawWithFrame:[self overflowPullDownRect_] inView:self];
    
    if ([self trackingAreasNeedUpdate_]) {
        [self updateTrackingAreas];
    }
}

-(void)drawBackground {
    // Fill gradient
    NSRect bounds = [self bounds];
    NSInteger gradientAngle = [[self superview] isFlipped] ? -90 : 90;
    [[self backgroundGradient] drawInRect:bounds angle:gradientAngle];
    
    // Bottom border
    NSPoint bottomLeft = bounds.origin;
    if ([[self superview] isFlipped])
        bottomLeft.y = bounds.size.height;
    NSPoint bottomRight = bottomLeft;
    bottomRight.x = bounds.size.width;
    [[self borderColor] setStroke];
    [NSBezierPath strokeLineFromPoint:bottomLeft toPoint:bottomRight];    
}

-(void)adjustSubviews {
    [self setTrackingAreasNeedUpdate_:YES];
    [self setGroupsNeedUpdate_:YES];
    [self setNeedsDisplay:YES];
}

-(NSButtonCell *)preparedButtonCellForGroup:(NSUInteger)groupIndex object:(NSUInteger)objectIndex {
    if (groupIndex >= [self numberOfGroups]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBar:preparedButtonCellForGroup:object: groupIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    SRScopeBarGroup *group = [[self groups] objectAtIndex:groupIndex];
    if (objectIndex >= [group numberOfObjects]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBar:preparedButtonCellForGroup:object: objectIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    if ([group numberOfObjects] == 0)
        return nil;
    NSDictionary *contentInfoBinding = [group infoForBinding:NSContentBinding];
    if (!contentInfoBinding)
        return [self preparedDataSourceCellForGroup_:groupIndex object:objectIndex];
    
    NSButtonCell *buttonCell = [[self buttonCell] retain];
    id bindingObject = [contentInfoBinding valueForKey:NSObservedObjectKey];
    NSString *keyPath = [contentInfoBinding valueForKey:NSObservedKeyPathKey];
    id dataObject = [[bindingObject valueForKeyPath:keyPath] objectAtIndex:objectIndex];
    NSString *title = ([self formatter] == nil) ? [dataObject description] : [[self formatter] stringForObjectValue:dataObject];
    [buttonCell setTitle:title];
    
    NSDictionary *contentValuesInfoBinding = [group infoForBinding:NSContentValuesBinding];
    if (contentValuesInfoBinding) {
        bindingObject = [contentValuesInfoBinding valueForKey:NSObservedObjectKey];
        keyPath = [contentValuesInfoBinding valueForKey:NSObservedKeyPathKey];
        NSString *contentValuesTitle = [[bindingObject valueForKeyPath:keyPath] objectAtIndex:objectIndex];
        [buttonCell setTitle:contentValuesTitle];
    }
    
    NSDictionary *imageInfoBinding = [group infoForBinding:NSImageBinding];
    if (imageInfoBinding) {
        bindingObject = [imageInfoBinding valueForKey:NSObservedObjectKey];
        keyPath = [imageInfoBinding valueForKey:NSObservedKeyPathKey];
        NSImage *image = [[bindingObject valueForKeyPath:keyPath] objectAtIndex:objectIndex];
        [buttonCell setImage:([image isEqualTo:[NSNull null]] ? nil : image)];
    }
    
    NSIndexSet *selectionIndexes = [[[self groups] objectAtIndex:groupIndex] selectionIndexes];
    [buttonCell setState:([selectionIndexes containsIndex:objectIndex] ? NSOnState : NSOffState)];
    
    return [buttonCell autorelease];
}

-(NSButtonCell *)preparedDataSourceCellForGroup_:(NSUInteger)groupIndex object:(NSUInteger)objectIndex {
    if (![self dataSource])
        return nil;
    
    id dataObject = [[self dataSource] scopeBar:self valueForObjectInGroup:groupIndex atIndex:objectIndex];
    NSButtonCell *buttonCell = [[self buttonCell] retain];
    NSString *title = [self formatter] == nil ? [dataObject description] : [[self formatter] stringForObjectValue:dataObject];
    [buttonCell setTitle:title];
    
    NSIndexSet *selectionIndexes = [[[self groups] objectAtIndex:groupIndex] selectionIndexes];
    [buttonCell setState:([selectionIndexes containsIndex:objectIndex] ? NSOnState : NSOffState)];
    
    NSImage *image = nil;
    if (dataSourceImplementsImageForObject_)
        image = [[self dataSource] scopeBar:self imageForObjectInGroup:groupIndex atIndex:objectIndex];
    [buttonCell setImage:image];
    return [buttonCell autorelease];
}

-(NSPopUpButtonCell *)preparedPopUpCellForGroup:(NSUInteger)groupIndex {
    if (groupIndex > [self numberOfGroups]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBar:preparedPopUpCellForGroup: groupIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    SRScopeBarGroup *group = [[self groups] objectAtIndex:groupIndex];
    NSPopUpButtonCell *popUpCell = [[self popUpButtonCell] retain];
    NSMenuItem *popUpMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [popUpMenuItem setState:NSOnState];
    NSIndexSet *selectionIndexes = [group selectionIndexes];
    if ([selectionIndexes count] > 1) {
        [popUpMenuItem setTitle:[group multipleSelectionPlaceholder]];
        [popUpMenuItem setImage:nil];
        [popUpCell setMenuItem:popUpMenuItem];
        [popUpCell setShowsBorderOnlyWhileMouseInside:NO];
        [popUpMenuItem release];
        return [popUpCell autorelease];
    }
    if ([selectionIndexes count] == 0) {
        [popUpMenuItem setTitle:[group noSelectionPlaceholder]];
        [popUpMenuItem setImage:nil];
        [popUpCell setMenuItem:popUpMenuItem];
        [popUpCell setShowsBorderOnlyWhileMouseInside:YES];
        [popUpMenuItem release];
        return [popUpCell autorelease];
    }
    
    // [selectionIndexes count] == 1
    [popUpCell setShowsBorderOnlyWhileMouseInside:NO];
    NSUInteger selectedIndex = [selectionIndexes firstIndex];
    NSDictionary *contentInfoBinding = [group infoForBinding:NSContentBinding];
    // If we're not using bindings, get data from the dataSource
    if (!contentInfoBinding) {        
        id dataObject = [[self dataSource] scopeBar:self valueForObjectInGroup:groupIndex atIndex:selectedIndex];
        NSString *title = ([self formatter] == nil) ? [dataObject description] : [[self formatter] stringForObjectValue:dataObject];
        if (!title)
            title = @"";
        [popUpMenuItem setTitle:title];
        
        NSImage *image = nil;
        if (dataSourceImplementsImageForObject_)
            image = [[self dataSource] scopeBar:self imageForObjectInGroup:groupIndex atIndex:selectedIndex];
        [popUpMenuItem setImage:image];
        [popUpCell setMenuItem:popUpMenuItem];
        [popUpMenuItem release];
        return [popUpCell autorelease];
    }
    
    id bindingObject, dataObject;
    NSString *keyPath;
    NSString *title;
    NSImage *image = nil;
    
    NSDictionary *contentValuesInfoBinding = [group infoForBinding:NSContentValuesBinding];
    if (contentValuesInfoBinding) {
        bindingObject = [contentValuesInfoBinding valueForKey:NSObservedObjectKey];
        keyPath = [contentValuesInfoBinding valueForKey:NSObservedKeyPathKey];
        dataObject = [bindingObject valueForKeyPath:keyPath];
        title = [dataObject objectAtIndex:selectedIndex];
    }
    else {
        bindingObject = [contentInfoBinding valueForKey:NSObservedObjectKey];
        keyPath = [contentInfoBinding valueForKey:NSObservedKeyPathKey];
        dataObject = [[bindingObject valueForKeyPath:keyPath] objectAtIndex:selectedIndex];
        title = ([self formatter] == nil) ? [dataObject description] : [[self formatter] stringForObjectValue:dataObject];
    }
    if (!title)
        title = @"";
    [popUpMenuItem setTitle:title];
    
    NSDictionary *imageInfoBinding = [group infoForBinding:NSImageBinding];
    if (imageInfoBinding) {
        bindingObject = [imageInfoBinding valueForKey:NSObservedObjectKey];
        keyPath = [imageInfoBinding valueForKey:NSObservedKeyPathKey];
        image = [[bindingObject valueForKeyPath:keyPath] objectAtIndex:selectedIndex];
        image = ([image isEqualTo:[NSNull null]] ? nil : image);
    }
    [popUpMenuItem setImage:image];
    [popUpCell setMenuItem:popUpMenuItem];
    [popUpMenuItem release];
    
    return [popUpCell autorelease];
}

-(void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize {
    [super resizeWithOldSuperviewSize:oldBoundsSize];
    [self setGroupsNeedUpdate_:YES];
    [self setNeedsDisplay:YES];
}

-(void)viewWillMoveToSuperview:(NSView *)newSuperview {
    if (!newSuperview && [self delegate]) 
        [[NSNotificationCenter defaultCenter] removeObserver:[self delegate] name:SRScopeBarSelectionDidChangeNotification object:nil];
}


#pragma mark -
#pragma mark Group management methods

-(SRScopeBarGroup *)addGroup {
    SRScopeBarGroup *newGroup = [[SRScopeBarGroup alloc] init];
    if (!groups_ || [groups_ count] == 0)
        [newGroup setShowsSeparator:NO];
    [self addGroup:newGroup];
    return [newGroup autorelease];
}

-(void)addGroup:(SRScopeBarGroup *)group {
    [self insertGroup:group atIndex:[self numberOfGroups]];
}

-(void)insertGroup:(SRScopeBarGroup *)group atIndex:(NSUInteger)groupIndex {
    if (groupIndex > [self numberOfGroups]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBar:insertGroup:atIndex: groupIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    [group setScopeBar:self];
    SRScopeBarGroupHelper *groupHelper = [[SRScopeBarGroupHelper alloc] initWithGroup:group inScopeBar:self];
    if (!groups_)
        groups_ = [[NSMutableArray alloc] initWithCapacity:1];
    [self willChangeValueForKey:@"groups"];
    [groups_ insertObject:groupHelper atIndex:groupIndex];
    [self didChangeValueForKey:@"groups"];
    [groupHelper release];
    [self adjustSubviews];
}

-(void)removeGroup:(SRScopeBarGroup *)group {
    SRScopeBarGroupHelper *groupHelper = [self groupHelperForGroup_:group];
    if (!groupHelper)
        return;
    NSUInteger groupHelperIndex = [groups_ indexOfObject:groupHelper];
    [self removeGroupAtIndex:groupHelperIndex];
}

-(void)removeGroupAtIndex:(NSUInteger)groupIndex {
    if (groupIndex >= [self numberOfGroups]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBar:removeGroup:atIndex: groupIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    SRScopeBarGroup *group = [[groups_ objectAtIndex:groupIndex] group];
    [self willChangeValueForKey:@"groups"];
    [group setScopeBar:nil];
    [groups_ removeObjectAtIndex:groupIndex];
    [self didChangeValueForKey:@"groups"];
    [self adjustSubviews];
}

-(NSUInteger)numberOfGroups {
    return [groups_ count];
}

-(SRScopeBarGroup *)groupWithIdentifier:(NSString *)identifier {
    for (SRScopeBarGroupHelper *groupHelper in groups_) {
        if ([[[groupHelper group] identifier] isEqualToString:identifier])
            return [groupHelper group];
    }
    return nil;
}

-(SRScopeBarGroup *)groupAtIndex:(NSUInteger)groupIndex {
    if (groupIndex >= [self numberOfGroups]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBar:removeGroup:atIndex: groupIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    
    return [[groups_ objectAtIndex:groupIndex] group];
}

-(NSUInteger)indexOfGroup:(SRScopeBarGroup *)group {
    for (NSUInteger groupIndex = 0; groupIndex < [self numberOfGroups]; groupIndex++) {
        if ([[groups_ objectAtIndex:groupIndex] group] == group)
            return groupIndex;
    }
    return NSNotFound;
}

-(void)moveGroupWithIndex:(NSUInteger)originalIndex toIndex:(NSUInteger)destinationIndex {
    if (originalIndex >= [self numberOfGroups]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBar:moveGroupWithIndex:toIndex: originalIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    if (destinationIndex >= [self numberOfGroups]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBar:moveGroupWithIndex:toIndex: destinationIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    SRScopeBarGroupHelper *groupHelper = [[groups_ objectAtIndex:originalIndex] retain];
    [groups_ removeObjectIdenticalTo:groupHelper];
    [groups_ insertObject:groupHelper atIndex:destinationIndex];
    [groupHelper release];
    [self adjustSubviews];
}


#pragma mark -
#pragma mark Content management methods

-(void)reloadData {
    for (SRScopeBarGroupHelper *groupHelper in groups_) {
        [groupHelper updateGroupDimensions];
        [self resetSelectionForGroup_:[groupHelper group]];
    }
    [self adjustSubviews];
}

-(void)reloadDataForGroup:(NSUInteger)groupIndex {
    if (groupIndex >= [self numberOfGroups]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBar:reloadDataForGroup: groupIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    SRScopeBarGroupHelper *groupHelper = [groups_ objectAtIndex:groupIndex];
    [groupHelper updateGroupDimensions];
    [self resetSelectionForGroup_:[groupHelper group]];
    [self adjustSubviews];
}

-(void)resetSelectionForGroup_:(SRScopeBarGroup *)group {
    if (!([group groupSelectionStyle] == SRScopeBarGroupSelectionStyleRadio)) 
        return;
    
    // Ensure radio-style groups have exactly one selected index
    NSMutableIndexSet *selectionIndexes = [[[group selectionIndexes] mutableCopy] autorelease];
    if ([selectionIndexes count] == 0) {
        for (NSUInteger proposedSelection = 0; proposedSelection < [group numberOfObjects]; proposedSelection++) {
            id proposedObject = [group objectAtIndex:proposedSelection];
            if (delegateImplementsShouldSelect_ && ![[self delegate] scopeBar:self shouldSelectObject:proposedObject]) 
                continue;
            [group setSelectionIndexes:[NSIndexSet indexSetWithIndex:proposedSelection]];
            break;
        }
    }
    else if ([selectionIndexes count] > 1)
        [group setSelectionIndexes:[NSIndexSet indexSetWithIndex:[selectionIndexes firstIndex]]];
}


#pragma mark -
#pragma mark Event handling methods

-(void)mouseEntered:(NSEvent *)theEvent {
    NSPoint eventPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if ([self mouse:eventPoint inRect:[self overflowPullDownRect_]]) {
        trackingOverflow_ = YES;
        [[self overflowPullDownCell] mouseEntered:theEvent];
        return;
    }
    
    for (SRScopeBarGroupHelper *groupHelper in groups_) {
        if ([self mouse:eventPoint inRect:[groupHelper frame]]) {
            trackingGroup_ = groupHelper;
            [(SRScopeBarGroupHelper *)trackingGroup_ mouseEntered:theEvent];
        }
    }
}

-(void)mouseExited:(NSEvent *)theEvent {
    if (trackingOverflow_) {
        trackingOverflow_ = NO;
        [[self overflowPullDownCell] mouseExited:theEvent];
        return;
    }
    
    [(SRScopeBarGroupHelper *)trackingGroup_ mouseExited:theEvent];
    trackingGroup_ = nil;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (trackingOverflow_) {
        [[self overflowPullDownCell] performClickWithFrame:[self overflowPullDownRect_] inView:self];
        [[self overflowPullDownCell] mouseExited:theEvent];
        return;
    }
    
    if (!trackingGroup_)
        return;
    [(SRScopeBarGroupHelper *)trackingGroup_ mouseDown:theEvent];
}

-(void)updateTrackingAreas {
    trackingAreasNeedUpdate_ = NO;
    for (NSTrackingArea *trackingArea in [self trackingAreas])
        [self removeTrackingArea:trackingArea];
    
    if ([overflowPullDownCell_ numberOfItems] > 1) {
        NSTrackingArea *overflowTrackingArea = [[NSTrackingArea alloc] initWithRect:[self overflowPullDownRect_] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:nil];
        [self addTrackingArea:overflowTrackingArea];
        [overflowTrackingArea autorelease];
    }
    
    for (SRScopeBarGroupHelper *groupHelper in groups_)
        [groupHelper addTrackingAreas];
}

-(void)overflowPullDownItemSelected:(id)sender {
    id selectedObject = [[[[self overflowPullDownCell] selectedItem] representedObject] retain];
    
    SRScopeBarGroup *group = [self groupContainingObject_:selectedObject];
    if (!group) {
        [selectedObject release];
        return;
    }
    NSUInteger objectIndex = [group indexForObject:selectedObject];
    
    if (delegateImplementsShouldSelect_ && ![[self delegate] scopeBar:self shouldSelectObject:selectedObject]) {
        [selectedObject release];
        return;
    }
    
    [group didClickObject:objectIndex];
    [self adjustSubviews];
    [selectedObject release];
}

#pragma mark -
#pragma mark Private utility methods

/* 
 * Layout algorithm:  
 *
 * This method is initiated when the control is resized or after adjustSubviews is called.  The method resets all groups to a fully expanded state
 * and then collapses them as necessary to fit the control's available width.  The SRScopeBarGroupHelper class maintains state information for 
 * each group including its frame within the control.  This method determines the designated frame for each group and passes that frame to the 
 * helper class which then parses its available space to the items in that group.  
 *
 * The method begins by determining the maximum expanded size of each group.  If there is sufficient room in the control to fit all groups at
 * max size, it sets each group to max size and returns.  If there isn't sufficent space, it collapses the groups one-by-one starting with the
 * right-most group (if possible - some groups won't collapse due to canCollapse == NO or delegate implementing ...shouldCollapse... method).
 * If all groups are collapsed (or can't collapse) then the method peels off groups one-by-one starting with the right-most group into the 
 * overflow pop up button.  Once the groups are collapsed to a size that will fit into the control, the method determines how much each group
 * should be resized from its max size.  It determines what each group's max size and min size are and compares how much each group will need to
 * collapse compared to how much the entire control needs to collapse to fit into the allotted space.  Those groups that have the furthest
 * to go to adjust to min size will adjusted the most.  Thus, those groups with large items will be resized first.
 *
 * Once the updated frame is passed to the helper class, it takes that frame and does a similar procedure to the elements inside the group.
 * Larger items are resized first so that all elements adjust proportionately to arrive at min size simultaneously.  Frames for each element are
 * stored in each SRScopeBarItem.
 */
-(void)calcSize {
    [self setGroupsNeedUpdate_:NO];
    
    // Start from an expanded, unpeeled state
    [groups_ makeObjectsPerformSelector:@selector(unpeel)];
    [self resetOverflowPullDownCell_];
    
    for (SRScopeBarGroupHelper *groupHelper in groups_) {
        if ([self autoResizesGroups])
            [[groupHelper group] setCollapsed:NO];
        [groupHelper updateGroupDimensions];
    }
    
    NSRect scopeBarBounds = [self bounds];
    NSInteger totalIntergroupSpacing = ([groups_ count] - 1) * SRScopeBarGroupSpacing;
    NSInteger widthAvailable = scopeBarBounds.size.width - (2 * SRScopeBarEndPadding) - totalIntergroupSpacing;
    NSUInteger accessoriesXPosition = NSMaxX(scopeBarBounds) - SRScopeBarEndPadding;
    
    // If an accessory view is being used, set the frame and adjust the layout to fit
    NSUInteger accessoryViewWidthAdjustment = 0;
    if ([self accessoryView]) {
        NSUInteger accessoryWidth = [[self accessoryView] frame].size.width;
        NSUInteger accessoryHeight = [[self accessoryView] frame].size.height;
        NSUInteger originX = accessoriesXPosition - accessoryWidth;
        NSUInteger originY = (scopeBarBounds.size.height - accessoryHeight) / 2;
        [[self accessoryView] setFrame:NSMakeRect(originX, originY, accessoryWidth, accessoryHeight)];
        accessoryViewWidthAdjustment = accessoryWidth + SRScopeBarAccessorySpacing;
        widthAvailable -= accessoryViewWidthAdjustment;
        accessoriesXPosition -= accessoryViewWidthAdjustment;
    }
    
    // If autoresizing is turned off, set all groups to max size
    if (![self autoResizesGroups]) {
        [self resetGroupsToMaxWidth_];
        return;
    }
    
    // If groups don't fit in available space, continue to collapse groups until they fit
    NSInteger totalMinimumWidth = [self sumOfMinimumWidthForAllGroups_];
    BOOL ableToCollapseGroup = YES;
    while (totalMinimumWidth > widthAvailable && ableToCollapseGroup) {
        ableToCollapseGroup = [self collapseRightMostGroup_];
        totalMinimumWidth = [self sumOfMinimumWidthForAllGroups_];
    }
    
    // If we couldn't collapse enough groups to make them fit, we'll have to use the overflow menu, so factor in the size of its cell to the layout
    NSUInteger overflowPullDownWidth = [[self overflowPullDownCell] cellSize].width;
    if (!ableToCollapseGroup) {
        NSUInteger originX = accessoriesXPosition - overflowPullDownWidth;
        NSUInteger overflowHeight = [[self overflowPullDownCell] cellSize].height;
        [self setOverflowPullDownRect_:NSMakeRect(originX, (scopeBarBounds.size.height - overflowHeight) / 2, overflowPullDownWidth, overflowHeight)];
        widthAvailable -= overflowPullDownWidth + SRScopeBarOverflowSpacing;
    }
    
    // If we couldn't collapse any further, but groups still don't fit in available space, peel them off to the overflow menu
    if (!ableToCollapseGroup && totalMinimumWidth > widthAvailable) {
        [self peelOffItemsToFitInWidth_:widthAvailable];
        totalMinimumWidth = [self sumOfMinimumWidthForAllGroups_];
        totalIntergroupSpacing = ([self countOfUnpeeledGroups_] - 1) * SRScopeBarGroupSpacing;
        widthAvailable = scopeBarBounds.size.width - (2 * SRScopeBarEndPadding) - accessoryViewWidthAdjustment - totalIntergroupSpacing - overflowPullDownWidth;
        if (totalMinimumWidth > 0)
            widthAvailable -= SRScopeBarOverflowSpacing;
    }
    
    // If all groups fit at maximum size then use this branch vice the resizing algorithm below
    NSUInteger totalMaximumWidth = [self sumOfMaximumWidthForAllGroups_];
    if (totalMaximumWidth <= widthAvailable) {
        [self resetGroupsToMaxWidth_];
        return;
    }
    
    // Resize each group proportionate to the delta of its max and min width
    NSInteger totalWidthDelta = totalMaximumWidth - totalMinimumWidth;
    NSInteger totalWidthAdjustment = totalMaximumWidth - widthAvailable;
    NSInteger groupWidthAdjustment;
    NSInteger widthAdjustmentRemaining = totalWidthAdjustment;
    NSInteger xPosition = SRScopeBarEndPadding;
    for (SRScopeBarGroupHelper *groupHelper in groups_) {
        NSInteger groupMaxWidth = [groupHelper maximumWidth];
        NSInteger groupMinWidth = [groupHelper minimumWidth];
        NSInteger groupWidthDelta = groupMaxWidth - groupMinWidth;
        if (groupHelper == [groups_ lastObject])
            groupWidthAdjustment = widthAdjustmentRemaining;
        else {
            groupWidthAdjustment = round((CGFloat)groupWidthDelta / (CGFloat)totalWidthDelta * (CGFloat)totalWidthAdjustment);
            widthAdjustmentRemaining -= groupWidthAdjustment;
        }
        NSRect groupFrame = NSMakeRect(xPosition, scopeBarBounds.origin.y, (groupMaxWidth - groupWidthAdjustment), scopeBarBounds.size.height);
        [groupHelper setFrame:groupFrame];
        xPosition += (groupFrame.size.width + SRScopeBarGroupSpacing);
    }
}

-(void)resetGroupsToMaxWidth_ {
    NSInteger xPosition = SRScopeBarEndPadding;
    for (SRScopeBarGroupHelper *groupHelper in groups_) {
        NSRect groupFrame = NSMakeRect(xPosition, [self bounds].origin.y, [groupHelper maximumWidth], [self bounds].size.height);
        [groupHelper setFrame:groupFrame];
        xPosition += (groupFrame.size.width + SRScopeBarGroupSpacing);
    }
}

-(void)resetGroupsToZeroWidth_ {
    for (SRScopeBarGroupHelper *groupHelper in groups_) {
        [groupHelper setFrame:NSZeroRect];
    }
}

-(BOOL)collapseRightMostGroup_ {
    for (SRScopeBarGroupHelper *groupHelper in [groups_ reverseObjectEnumerator]) {
        SRScopeBarGroup *group = [groupHelper group];
        if ([group collapsed])
            continue;
        [group setCollapsed:YES];
        if (![group collapsed]) // Delegate can override attempt to collapse the group
            continue;
        [groupHelper updateGroupDimensions];
        return YES;
    }
    return NO;
}

-(void)peelOffItemsToFitInWidth_:(NSUInteger)width {
    NSMenu *pullDownMenu = [[self overflowPullDownCell] menu];
    for (SRScopeBarGroupHelper *groupHelper in [groups_ reverseObjectEnumerator]) {
        NSArray *peeledItems = nil;
        NSUInteger totalMinimumWidth = 0;
        do {
            peeledItems = [groupHelper peelOffNextItem];
            totalMinimumWidth = [self sumOfMinimumWidthForAllGroups_];
            for (NSMenuItem *menuItem in [peeledItems reverseObjectEnumerator])
                [pullDownMenu insertItem:menuItem atIndex:1];
        } while (peeledItems != nil && totalMinimumWidth > width);
        
        if (groupHelper != [groups_ objectAtIndex:0])
            width += SRScopeBarGroupSpacing;
        if (totalMinimumWidth <= width)
            break;
        NSMenuItem *separator = [NSMenuItem separatorItem];
        [pullDownMenu insertItem:separator atIndex:1];
    }
    [[self overflowPullDownCell] setMenu:pullDownMenu];
}

-(NSUInteger)countOfUnpeeledGroups_ {
    NSUInteger unpeeledCount = 0;
    for (SRScopeBarGroupHelper *groupHelper in groups_) {
        if (![groupHelper isPeeled])
            unpeeledCount++;
    }
    return unpeeledCount;
}

-(void)resetOverflowPullDownCell_ {
    NSMenu *pullDownMenu = [[self overflowPullDownCell] menu];
    for (NSUInteger menuItemIndex = [pullDownMenu numberOfItems] - 1; menuItemIndex > 0; menuItemIndex--)
        [pullDownMenu removeItemAtIndex:menuItemIndex];
}

-(SRScopeBarGroupHelper *)groupHelperForGroup_:(SRScopeBarGroup *)theGroup {
    for (SRScopeBarGroupHelper *groupHelper in groups_) {
        if ([groupHelper group] == theGroup)
            return groupHelper;
    }
    return nil;
}

-(NSInteger)sumOfMaximumWidthForAllGroups_ {
    NSInteger totalMaximumWidth = 0;
    for (SRScopeBarGroupHelper *groupHelper in groups_) 
        totalMaximumWidth += [groupHelper maximumWidth];
    
    return totalMaximumWidth;
}

-(NSInteger)sumOfMinimumWidthForAllGroups_ {
    NSInteger totalMinimumWidth = 0;
    for (SRScopeBarGroupHelper *groupHelper in groups_) 
        totalMinimumWidth += [groupHelper minimumWidth];
    
    return totalMinimumWidth;
}

-(SRScopeBarGroup *)groupContainingObject_:(id)object {
    NSArray *groups = [self groups];
    for (SRScopeBarGroup *group in groups) {
        if ([group indexForObject:object] != NSNotFound)
            return group;
    }
    return nil;
}

@end