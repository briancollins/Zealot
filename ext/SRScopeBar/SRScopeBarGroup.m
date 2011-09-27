/* 
 Copyright (c) 2009, Sean Rich
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither Sean Rich nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SRScopeBarGroup.h"
#import "SRScopeBar.h"

@interface SRScopeBarGroup (SRScopeBarGroupPrivateMethods)
-(void)didClickObject_:(NSUInteger)objectIndex alwaysSetToOnState:(BOOL)alwaysOn;
@end

@implementation SRScopeBarGroup

@synthesize identifier = identifier_;
@synthesize label = label_;
@synthesize attributedLabel = attributedLabel_;
@synthesize groupSelectionStyle = selectionStyle_;
@synthesize showsSeparator = showsSeparator_;
@synthesize showsLabel = showsLabel_;
@synthesize collapsed = collapsed_;
@synthesize selectionIndexes = selectionIndexes_;
@synthesize scopeBar = scopeBar_;
@synthesize multipleSelectionPlaceholder = multipleSelectionPlaceholder_;
@synthesize noSelectionPlaceholder = noSelectionPlaceholder_;


#pragma mark -
#pragma mark Initializers

+(void)initialize {
    if (self != [SRScopeBarGroup class])
        return;
        
    [self exposeBinding:NSContentBinding];
    [self exposeBinding:NSContentValuesBinding];
    [self exposeBinding:NSImageBinding];
}

-(id)init {
    return [self initWithIdentifier:nil withSelectionStyle:SRScopeBarGroupSelectionStyleRadio];
}

-(id)initWithIdentifier:(NSString *)theIdentifier withSelectionStyle:(SRScopeBarGroupSelectionStyle)style {
    if (!(self = [super init]))
        return nil;
    
    [self setIdentifier:theIdentifier];
    [self setGroupSelectionStyle:style];
    [self setShowsSeparator:YES];
    [self setSelectionIndexes:[NSIndexSet indexSet]];
    
    return self;
}

-(id)initWithCoder:(NSCoder *)coder {
    if (![coder allowsKeyedCoding])
        return nil;
    
    [self setIdentifier:[coder decodeObjectForKey:@"SRScopeBarGroup identifier"]];
    [self setLabel:[coder decodeObjectForKey:@"SRScopeBarGroup label"]];
    [self setAttributedLabel:[coder decodeObjectForKey:@"SRScopeBarGroup attributedLabel"]];
    [self setGroupSelectionStyle:[coder decodeIntForKey:@"SRScopeBarGroup groupSelectionStyle"]];
    [self setShowsSeparator:[coder decodeBoolForKey:@"SRScopeBarGroup showsSeparator"]];
    [self setShowsLabel:[coder decodeBoolForKey:@"SRScopeBarGroup showsLabel"]];
    [self setScopeBar:[coder decodeObjectForKey:@"SRScopeBarGroup scopeBar"]];
    [self setSelectionIndexes:[coder decodeObjectForKey:@"SRScopeBarGroup selectionIndexes"]];
    [self setMultipleSelectionPlaceholder:[coder decodeObjectForKey:@"SRScopeBarGroup multipleSelectionPlaceholder"]];
    [self setNoSelectionPlaceholder:[coder decodeObjectForKey:@"SRScopeBarGroup noSelectionPlaceholder"]];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    if (![coder allowsKeyedCoding])
        return;
    
    [coder encodeObject:[self identifier] forKey:@"SRScopeBarGroup identifier"];
    [coder encodeObject:[self label] forKey:@"SRScopeBarGroup label"];
    [coder encodeObject:attributedLabel_ forKey:@"SRScopeBarGroup attributedLabel"];
    [coder encodeInt:[self groupSelectionStyle] forKey:@"SRScopeBarGroup groupSelectionStyle"];
    [coder encodeBool:[self showsSeparator] forKey:@"SRScopeBarGroup showsSeparator"];
    [coder encodeBool:[self showsLabel] forKey:@"SRScopeBarGroup showsLabel"];
    [coder encodeObject:[self selectionIndexes] forKey:@"SRScopeBarGroup selectionIndexes"];
    [coder encodeConditionalObject:[self scopeBar] forKey:@"SRScopeBarGroup scopeBar"];
    [coder encodeObject:multipleSelectionPlaceholder_ forKey:@"SRScopeBarGroup multipleSelectionPlaceholder"];
    [coder encodeObject:noSelectionPlaceholder_ forKey:@"SRScopeBarGroup noSelectionPlaceholder"];
}

#pragma mark -
#pragma mark Destructors

-(void)dealloc {
    [identifier_ release];
    [label_ release];
    [attributedLabel_ release];
    [selectionIndexes_ release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark Accessors

-(void)setShowsSeparator:(BOOL)flag {
    showsSeparator_ = flag;
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];
}

-(void)setLabel:(NSString *)theLabel {
    if ([label_ isEqualToString:theLabel])
        return;
    [label_ release];
    label_ = [theLabel copy];
    if (label_ == nil && attributedLabel_ == nil)
        [self setShowsLabel:NO];
    else
        [self setShowsLabel:YES];
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];
}

-(void)setShowsLabel:(BOOL)showsLabel {
    showsLabel_ = showsLabel;
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];
}

-(NSAttributedString *)attributedLabel {
    if (!attributedLabel_) {
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[scopeBar_ labelColor], NSForegroundColorAttributeName, [NSFont boldSystemFontOfSize:11], NSFontAttributeName, nil];
        return [[[NSAttributedString alloc] initWithString:[self label] attributes:attributes] autorelease];
    }
    return [[attributedLabel_ copy] autorelease];
}

-(void)setAttributedLabel:(NSAttributedString *)attributedLabel {
    if ([attributedLabel isEqualToAttributedString:attributedLabel_])
        return;
    [attributedLabel_ release];
    attributedLabel_ = [attributedLabel copy];
    if (attributedLabel_ == nil && label_ == nil)
        [self setShowsLabel:NO];
    else
        [self setShowsLabel:YES];
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];
}

-(NSString *)multipleSelectionPlaceholder {
    if (!multipleSelectionPlaceholder_)
        return @"<Multiple>";
    return [[multipleSelectionPlaceholder_ copy] autorelease];
}

-(void)setMultipleSelectionPlaceholder:(NSString *)placeholder {
    if ([multipleSelectionPlaceholder_ isEqualToString:placeholder])
        return;
    [multipleSelectionPlaceholder_ release];
    multipleSelectionPlaceholder_ = [placeholder copy];
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];
}

-(NSString *)noSelectionPlaceholder {
    if (noSelectionPlaceholder_)
        return [[noSelectionPlaceholder_ copy] autorelease];
    
    if ([self identifier])
        return [[[self identifier] copy] autorelease];
    return @"<Untitled>";
}

-(void)setNoSelectionPlaceholder:(NSString *)placeholder {
    if ([noSelectionPlaceholder_ isEqualToString:placeholder])
        return;
    [noSelectionPlaceholder_ release];
    noSelectionPlaceholder_ = [placeholder copy];
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];
}

-(void)setGroupSelectionStyle:(SRScopeBarGroupSelectionStyle)selectionStyle {
    selectionStyle_ = selectionStyle;
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];
}

-(void)setCollapsed:(BOOL)shouldCollapse {
    if (collapsed_ == shouldCollapse)
        return;
    
    BOOL delegateImplementsShouldCollapse = [[[self scopeBar] valueForKey:@"delegateImplementsShouldCollapse_"] boolValue];
    if (shouldCollapse && delegateImplementsShouldCollapse && ![[[self scopeBar] delegate] scopeBar:[self scopeBar] shouldCollapseGroup:self])
        return;
    
    BOOL delegateImplementsShouldExpand = [[[self scopeBar] valueForKey:@"delegateImplementsShouldExpand_"] boolValue];
    if (!shouldCollapse && delegateImplementsShouldExpand && ![[[self scopeBar] delegate] scopeBar:[self scopeBar] shouldExpandGroup:self])
        return;
    
    collapsed_ = shouldCollapse;
}

-(id)objectAtIndex:(NSUInteger)objectIndex {
    if (objectIndex >= [self numberOfObjects]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBarGroup:objectAtIndex: objectIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    
    NSDictionary *contentInfoDictionary = [self infoForBinding:NSContentBinding];
    // If content is not bound, try to use dataSource
    if (contentInfoDictionary) {
        id object = [contentInfoDictionary valueForKey:NSObservedObjectKey];
        NSString *keyPath = [contentInfoDictionary valueForKey:NSObservedKeyPathKey];
        return [[object valueForKeyPath:keyPath] objectAtIndex:objectIndex];
    }
    id dataSource = [[self scopeBar] dataSource];
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return nil;
    id dataObject = (dataSource == nil ? nil : [dataSource scopeBar:[self scopeBar] valueForObjectInGroup:groupIndex atIndex:objectIndex]);
    return [[dataObject retain] autorelease];
}

-(NSUInteger)indexForObject:(id)theObject {
    NSDictionary *contentInfoDictionary = [self infoForBinding:NSContentBinding];
    // Try content binding first, otherwise use dataSource
    if (contentInfoDictionary) {
        id object = [contentInfoDictionary valueForKey:NSObservedObjectKey];
        NSString *keyPath = [contentInfoDictionary valueForKey:NSObservedKeyPathKey];
        NSArray *contentObject = [object valueForKeyPath:keyPath];
        return [contentObject indexOfObject:theObject];
    }
    id dataSource = [[self scopeBar] dataSource];
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (!dataSource || groupIndex == NSNotFound)
        return NSNotFound;
    for (NSUInteger objectIndex = 0; objectIndex < [self numberOfObjects]; objectIndex++) {
        id dataObject = [dataSource scopeBar:[self scopeBar] valueForObjectInGroup:groupIndex atIndex:objectIndex];
        if (dataObject == theObject)
            return objectIndex;
    }
    return NSNotFound;
}

-(NSUInteger)numberOfObjects {
    NSDictionary *contentInfoDictionary = [self infoForBinding:NSContentBinding];
    // If content is not bound, try to use dataSource
    if (!contentInfoDictionary) {
        id dataSource = [[self scopeBar] dataSource];
        NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
        if (groupIndex == NSNotFound)
            return -1;
        return (dataSource == nil ? 0 : [dataSource scopeBar:[self scopeBar] numberOfObjectsInScopeBarGroup:groupIndex]);
    }
    id object = [contentInfoDictionary valueForKey:NSObservedObjectKey];
    NSString *keyPath = [contentInfoDictionary valueForKey:NSObservedKeyPathKey];
    NSUInteger count = [[object valueForKeyPath:keyPath] count];
    return count;
}


#pragma mark -
#pragma mark Selection methods

-(id)selectedObject {
    return [[self selectedObjects] objectAtIndex:0];
}

-(NSArray *)selectedObjects {
    NSMutableArray *selectionArray = [NSMutableArray array];
    NSIndexSet *selectionIndexes = [self selectionIndexes];
    for (NSUInteger objectIndex = [selectionIndexes firstIndex]; objectIndex != NSNotFound; objectIndex = [selectionIndexes indexGreaterThanIndex:objectIndex])
        [selectionArray addObject:[self objectAtIndex:objectIndex]];
    return ([selectionArray count] == 0 ? nil : selectionArray);
}

-(void)didClickObject:(NSUInteger)objectIndex {
    [self didClickObject_:objectIndex alwaysSetToOnState:NO];
}

-(void)didClickObject_:(NSUInteger)objectIndex alwaysSetToOnState:(BOOL)alwaysOn {
    if (objectIndex >= [self numberOfObjects]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBarGroup:didClickObject_:alwaysSetToOnState: objectIndex invalid" userInfo:nil];
        @throw rangeException;
    }    
    NSMutableIndexSet *selectedIndexes = [[[self selectionIndexes] mutableCopy] autorelease];
    NSCellStateValue currentState = [selectedIndexes containsIndex:objectIndex] ? NSOnState : NSOffState;

    // Item is already set to be on - nothing to do
    if (alwaysOn == YES && currentState == NSOnState)
        return;
    
    // For radio style groups, set the current selection to the given objectIndex
    if ([self groupSelectionStyle] == SRScopeBarGroupSelectionStyleRadio) {
        [self setSelectionIndexes:[NSIndexSet indexSetWithIndex:objectIndex]];
        return;
    }
    
    if (currentState == NSOnState)
        [selectedIndexes removeIndex:objectIndex];
    else
        [selectedIndexes addIndex:objectIndex];
    [self setSelectionIndexes:selectedIndexes];
}

-(void)selectObject:(id)theObject {
    NSUInteger objectIndex = [self indexForObject:theObject];
    if (objectIndex == NSNotFound) {
        NSException *invalidException = [NSException exceptionWithName:NSInvalidArgumentException reason:@"SRScopeBarGroup:selectObject theObject not a member of this group" userInfo:nil];
        @throw invalidException;
    }
    [self selectObjectWithIndex:objectIndex];
}

-(void)selectObjectWithIndex:(NSInteger)objectIndex {
    if (objectIndex < 0 || objectIndex >= [self numberOfObjects]) {
        NSException *rangeException = [NSException exceptionWithName:NSRangeException reason:@"SRScopeBarGroup:selectObjectWithIndex: objectIndex invalid" userInfo:nil];
        @throw rangeException;
    }
    [self didClickObject_:objectIndex alwaysSetToOnState:YES];
}


#pragma mark -
#pragma mark Binding methods

-(void)bind:(NSString *)binding toObject:(id)observableController withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {
    [super bind:binding toObject:observableController withKeyPath:keyPath options:options];
    if ([binding isEqualToString:NSContentBinding]) 
        [observableController addObserver:self forKeyPath:NSSelectionIndexesBinding options:NSKeyValueObservingOptionNew context:nil];
}

-(void)unbind:(NSString *)binding {
    if ([binding isEqualToString:NSContentBinding]) {
        id controller = [[self infoForBinding:NSContentBinding] objectForKey:NSObservedObjectKey];
        [controller removeObserver:self forKeyPath:NSSelectionIndexesBinding];
    }
    [super unbind:binding];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (![keyPath isEqualToString:NSSelectionIndexesBinding])
        return;
    NSAssert([object isKindOfClass:[NSArrayController class]], @"SRScopeBarGroup: Observing selectionIndexes from object not of class NSArrayController");
    NSIndexSet *selectionIndexes = [(NSArrayController *)object selectionIndexes];
    [self setSelectionIndexes:selectionIndexes];
}

// Content binding is read only
-(NSArray *)content {
    return nil;
}

-(void)setContent:(NSArray *)theContent {
    if (![self infoForBinding:NSContentBinding])
        return;
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];
}

// Content values binding is read only
-(NSArray *)contentValues {
    return nil;
}

-(void)setContentValues:(NSArray *)theContentValues {
    if (![self infoForBinding:NSContentBinding])
        return;
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];
}

// Image binding is read only
-(NSArray *)image {
    return nil;
}

-(void)setImage:(NSArray *)imageArray {
    if (![self infoForBinding:NSContentBinding])
        return;
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];
}

-(NSIndexSet *)selectionIndexes {
    return [[selectionIndexes_ copy] autorelease];
}

-(void)setSelectionIndexes:(NSIndexSet *)theIndexes {
    BOOL indexesHaveChanged = [selectionIndexes_ isEqualToIndexSet:theIndexes];
    [selectionIndexes_ release];
    selectionIndexes_ = [theIndexes copy];
    
    NSDictionary *contentInfoDictionary = [self infoForBinding:NSContentBinding];
    id object = [contentInfoDictionary objectForKey:NSObservedObjectKey];
    if ([object isKindOfClass:[NSArrayController class]]) {
        [(NSArrayController *)object setSelectionIndexes:selectionIndexes_];
    }
    
    NSUInteger groupIndex = [[self scopeBar] indexOfGroup:self];
    if (groupIndex == NSNotFound)
        return;
    [[self scopeBar] reloadDataForGroup:groupIndex];

    if (!indexesHaveChanged) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self identifier], SRGroupIdentifierKey, nil];
        NSNotification *selectionNotification = [NSNotification notificationWithName:SRScopeBarSelectionDidChangeNotification object:[self scopeBar] userInfo:userInfo]; 
        [[NSNotificationCenter defaultCenter] postNotification:selectionNotification];
    }
}

@end