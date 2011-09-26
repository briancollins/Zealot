/* 
 Copyright (c) 2009, Sean Rich
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither Sean Rich nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

#pragma mark -
#pragma mark Constants

typedef enum {
    SRScopeBarGroupSelectionStyleRadio,
    SRScopeBarGroupSelectionStyleMultipleSelection
} SRScopeBarGroupSelectionStyle;

@class SRScopeBar;

#pragma mark -
@interface SRScopeBarGroup : NSObject <NSCoding> {

  @private
    NSString                        *identifier_;
    NSString                        *label_;
    NSAttributedString              *attributedLabel_;
    SRScopeBarGroupSelectionStyle   selectionStyle_;
    BOOL                            showsSeparator_;
    BOOL                            collapsed_;
    BOOL                            showsLabel_;
    NSIndexSet                      *selectionIndexes_;
    SRScopeBar                      *scopeBar_;
    NSString                        *multipleSelectionPlaceholder_;
    NSString                        *noSelectionPlaceholder_;
}

@property (assign, nonatomic) SRScopeBar                     *scopeBar;
@property (copy, nonatomic)   NSIndexSet                     *selectionIndexes;
@property (copy, nonatomic)   NSString                       *identifier;
@property (copy, nonatomic)   NSString                       *label;
@property (copy, nonatomic)   NSAttributedString             *attributedLabel;
@property (assign, nonatomic) SRScopeBarGroupSelectionStyle  groupSelectionStyle;
@property (assign, nonatomic) BOOL                           showsSeparator; 
@property (assign, nonatomic) BOOL                           showsLabel;
@property (assign, nonatomic) BOOL                           collapsed;
@property (copy, nonatomic)   NSString                       *multipleSelectionPlaceholder;
@property (copy, nonatomic)   NSString                       *noSelectionPlaceholder;

-(id)initWithIdentifier:(NSString *)theIdentifier withSelectionStyle:(SRScopeBarGroupSelectionStyle)style;

#pragma mark -
#pragma mark Accessors

-(id)objectAtIndex:(NSUInteger)objectIndex;
-(NSUInteger)indexForObject:(id)theObject;
-(NSUInteger)numberOfObjects;

#pragma mark -
#pragma mark Selection methods

-(id)selectedObject;
-(NSArray *)selectedObjects;
-(void)didClickObject:(NSUInteger)objectIndex;

-(void)selectObject:(id)theObject;
-(void)selectObjectWithIndex:(NSInteger)objectIndex;

@end