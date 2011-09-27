#import "ZEModel.h"

@interface ZEReplay : ZEModel

@property (nonatomic, retain) NSOrderedSet *replayPlayers;

- (id)initWithPath:(NSString *)path account:(NSString *)account;

@end
