#import "ZEModel.h"

@class ZEReplay, ZEPlayer;
@interface ZEReplayPlayer : ZEModel

@property (nonatomic, copy) NSString *race;
@property (nonatomic, retain) NSNumber *team;
@property (nonatomic, copy) NSString *outcome;
@property (nonatomic, retain) NSNumber *won;

@property (nonatomic, retain) ZEReplay *replay;
@property (nonatomic, retain) ZEPlayer *player;

@end
