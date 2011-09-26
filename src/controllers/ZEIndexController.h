@class SRScopeBar, SRScopebarGroup;
@interface ZEIndexController : NSViewController <SRScopeBarDataSource, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, retain) IBOutlet SRScopeBar *scopeBar;
@property (nonatomic, retain) SRScopeBarGroup *typeGroup;
@property (nonatomic, retain) SRScopeBarGroup *matchupGroup;
@property (nonatomic, retain) NSArray *types;
@property (nonatomic, retain) NSArray *matchups;

@end
