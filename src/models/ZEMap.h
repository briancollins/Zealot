#import "ZEModel.h"

@interface ZEMap : ZEModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSMutableSet *replays;
@end
