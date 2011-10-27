#import "SRScopeBar.h"
#import "SRScopeBarGroup.h"
#import "ZEIndexController.h"
#import "ZEAppDelegate.h"
#import "ZEReplayRowView.h"
#import "ZEReplay.h"
#import "ZEReplayPlayer.h"
#import "ZEPlayer.h"
#import "ZEMap.h"

@implementation ZEIndexController
@synthesize scopeBar, tableView, typeGroup, matchupGroup, types, matchups, arrayController, tableRow;

- (void)dealloc {
    self.scopeBar = nil;
    self.typeGroup = nil;
    self.matchupGroup = nil;
    self.types = nil;
    self.matchups = nil;
    self.tableView = nil;
    self.arrayController = nil;
    self.tableRow = nil;
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Initialization code here.
    }
    
    return self;
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

    [self.arrayController setManagedObjectContext:[ZEAppDelegate managedObjectContext]];
    [self.arrayController setEntityName:@"ZEReplay"];
    [self.arrayController fetch:self];
    [self.tableView reloadData];
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    NSData *archivedView = [NSKeyedArchiver archivedDataWithRootObject:self.tableRow];
    ZEReplayRowView *myViewCopy = [NSKeyedUnarchiver unarchiveObjectWithData:archivedView];
    ZEReplay *replay = [[self.arrayController content] objectAtIndex:row];
    
    NSMutableString *teamOne = [NSMutableString string];
    NSMutableString *teamTwo = [NSMutableString string];
    
    NSLog(@"%@", replay.originalPath);
    for (ZEReplayPlayer *rp in replay.replayPlayers) {
        if ([rp.team intValue] == 1) {
            [teamOne appendString:rp.player.name];            
        } else {
            [teamTwo appendString:rp.player.name];
        }
        
        NSLog(@"%@ %@", rp.player.name, rp.team);
    }
    
    NSLog(@"*****");
    
    [myViewCopy.teamOne setStringValue:teamOne];
    [myViewCopy.teamTwo setStringValue:teamTwo];

    return myViewCopy;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 60.0f;
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
