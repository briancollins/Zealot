#import "ZEReplay.h"
#import "ze_mpq.h"

@implementation ZEReplay
@dynamic replayPlayers;

- (id)initWithPath:(NSString *)path account:(NSString *)account {
    ZE_MPQ *mpq;
    ZE_RETVAL ret;
    CFStringRef account_id = NULL;
    CFStringRef region = NULL;
    CFDictionaryRef dict = NULL;
    CFArrayRef attributes = NULL;
    
    if ((self = [super initWithEntity:[self entity] insertIntoManagedObjectContext:nil])) {

        ret = ze_mpq_new_file(&mpq, (char *)[path UTF8String]);
        if (ret != ZE_SUCCESS) goto error;
        
        ret = ze_mpq_read_headers(mpq);
        if (ret != ZE_SUCCESS) goto error;
        
        

        ret = ze_mpq_read_initdata(mpq, &region, &account_id);
        if (ret != ZE_SUCCESS) goto error;
        
        ret = ze_mpq_read_attributes(mpq, &attributes);
        
        ZE_STREAM *s;
        ret = ze_mpq_read_file(mpq, "replay.details", &s);
        if (ret != ZE_SUCCESS) goto error;
        

        ret = ze_stream_deserialize(s, (CFTypeRef *)&dict);
        if (ret != ZE_SUCCESS) goto error;
        
        NSUInteger i = 0;
        for (NSDictionary *player in [(NSDictionary *)dict objectForKey:[NSNumber numberWithInt:0]]) {
            NSString *name = [player objectForKey:[NSNumber numberWithInt:0]];
            NSString *bnetId = [[player objectForKey:[NSNumber numberWithInt:1]] 
                                objectForKey:[NSNumber numberWithInt:4]];
            NSNumber *outcome = [player objectForKey:[NSNumber numberWithInt:8]];

            i++;
        }
        
        CFRelease(dict);
        CFRelease(region);
        CFRelease(account_id);
        CFRelease(attributes);
        ze_stream_close(s);
        ze_mpq_close(mpq);
    }
    
    return self;
    
error:
    NSLog(@"%d", ret);
    if (attributes != NULL) CFRelease(attributes), attributes = NULL;
    if (dict != NULL) CFRelease(dict), dict = NULL;
    if (account_id != NULL) CFRelease(account_id), account_id = NULL;
    if (region != NULL) CFRelease(region), region = NULL;
    ze_mpq_close(mpq);
    [self release];
    return nil;
}

@end
