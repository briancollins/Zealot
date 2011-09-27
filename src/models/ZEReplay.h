#import "ZEModel.h"

@interface ZEReplay : ZEModel

@property (nonatomic, retain) NSOrderedSet *replayPlayers;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *category;

- (id)initWithPath:(NSString *)path account:(NSString *)account;

@end
