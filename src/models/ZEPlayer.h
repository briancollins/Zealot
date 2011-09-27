#import "ZEModel.h"

@interface ZEPlayer : ZEModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bnetId;
@property (nonatomic, copy) NSString *region;
@property (nonatomic, retain) NSMutableSet *replayPlayers;

@end
