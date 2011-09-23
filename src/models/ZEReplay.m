#import "ZEReplay.h"
#import "ze_mpq.h"

@implementation ZEReplay

- (id)initWithPath:(NSString *)path account:(NSString *)account {
    ZE_MPQ *mpq;
    
    if ((self = [super init])) {
        ZE_RETVAL ret = ze_mpq_new_file(&mpq, (char *)[path UTF8String]);
        if (ret != ZE_SUCCESS) {
            goto error;
        }
        
        ret = ze_mpq_read_header(mpq);
        
        if (ret != ZE_SUCCESS) {
            goto error;
        }
        
        ret = ze_mpq_read_user_data(mpq);
        
        if (ret != ZE_SUCCESS) {
            goto error;
        }
        
        NSLog(@"%@", (NSDictionary *)mpq->replay_info);
        ze_mpq_close(mpq);
    }
    
    return self;
    
error:
    ze_mpq_close(mpq);
    [self release];
    return nil;
}

@end
