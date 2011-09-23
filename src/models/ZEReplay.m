#import "ZEReplay.h"
#import "ze_mpq.h"

@implementation ZEReplay

- (id)initWithPath:(NSString *)path account:(NSString *)account {
    if ((self = [super init])) {
        ZE_MPQ *mpq;
        
        if (ze_mpq_new(&mpq, (char *)[path UTF8String]) == ZE_SUCCESS) {
            NSLog(@"%@", [(NSDictionary *)mpq->replay_info allValues]);
        }
        // Initialization code here.
    }
    
    return self;
}

@end
