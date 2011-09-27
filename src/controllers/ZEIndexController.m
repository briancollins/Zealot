#import "SRScopeBar.h"
#import "SRScopeBarGroup.h"
#import "ZEIndexController.h"

@implementation ZEIndexController
@synthesize scopeBar, tableView, typeGroup, matchupGroup, types, matchups;

- (void)dealloc {
    self.scopeBar = nil;
    self.typeGroup = nil;
    self.matchupGroup = nil;
    self.types = nil;
    self.matchups = nil;
    self.tableView = nil;
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Initialization code here.
    }
    
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return 3;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    NSTableRowView *rv = [[[NSTableRowView alloc] init] autorelease];
    NSTextField *v = [[[NSTextField alloc] initWithFrame:rv.bounds] autorelease];
    v.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [v setStringValue:@"Hello"];
    [v setBezeled:NO];
    [v setDrawsBackground:NO];
    [v setEditable:NO];
    [v setSelectable:NO];
    [rv addSubview:v];
    return rv;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.types = [NSArray arrayWithObjects:@"All", @"1v1", @"2v2", @"3v3", @"4v4", @"FFA", nil];
    self.matchups = [NSArray arrayWithObjects:@"All", @"TvT", @"TvP", @"TvZ", nil];
    
    self.scopeBar.dataSource = self;
    self.typeGroup = [[[SRScopeBarGroup alloc]
                               initWithIdentifier:@"type"
                               withSelectionStyle:SRScopeBarGroupSelectionStyleRadio]
                              autorelease];
    self.typeGroup.showsSeparator = NO;
    self.typeGroup.showsLabel = NO;
    self.matchupGroup = [[[SRScopeBarGroup alloc]
                                   initWithIdentifier:@"matchup"
                                   withSelectionStyle:SRScopeBarGroupSelectionStyleRadio]
                                  autorelease];
    self.matchupGroup.showsLabel = NO;
    [self.scopeBar setGroups:[NSArray arrayWithObjects:self.typeGroup, self.matchupGroup, nil]];
    [self.typeGroup selectObjectWithIndex:0];
    [self.matchupGroup selectObjectWithIndex:0];
}


-(NSUInteger)scopeBar:(SRScopeBar *)scopeBar numberOfObjectsInScopeBarGroup:(NSUInteger)groupIndex {
    if (groupIndex == 0) {
        return self.types.count;
    } else {
        return self.matchups.count;
    }
}

-(id)scopeBar:(SRScopeBar *)scopeBar valueForObjectInGroup:(NSUInteger)groupIndex atIndex:(NSUInteger)objectIndex {
    if (groupIndex == 0) {
        return [self.types objectAtIndex:objectIndex];
    } else {
        return [self.matchups objectAtIndex:objectIndex];
    }
}

@end
