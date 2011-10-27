#import "ZEModel.h"
@class ZEMap;

@interface ZEReplay : ZEModel

@property (nonatomic, retain) NSMutableOrderedSet *replayPlayers;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *region;
@property (nonatomic, copy) NSString *fileHash;
@property (nonatomic, copy) NSString *originalPath;
@property (nonatomic, retain) NSNumber *duration;
@property (nonatomic, retain) ZEMap *map;

- (id)initWithPath:(NSString *)path account:(NSString *)account;

@end
