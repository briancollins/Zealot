#import "ZEReplay.h"
#import "ze_mpq.h"

@implementation ZEReplay

- (id)initWithPath:(NSString *)path account:(NSString *)account {
    ZE_MPQ *mpq;
    ZE_RETVAL ret;
    
    if ((self = [super init])) {
        ret = ze_mpq_new_file(&mpq, (char *)[path UTF8String]);
        if (ret != ZE_SUCCESS) goto error;
        
        ret = ze_mpq_read_header(mpq);
        if (ret != ZE_SUCCESS) goto error;
        
        ret = ze_mpq_read_user_data(mpq);
        if (ret != ZE_SUCCESS) goto error;
        
        ret = ze_mpq_read_archive_header(mpq);
        if (ret != ZE_SUCCESS) goto error;
        
        ret = ze_mpq_read_tables(mpq);
        if (ret != ZE_SUCCESS) goto error;
        
        uint8_t *file;
        off_t len;
        ret = ze_mpq_read_file(mpq, "replay.details", &file, &len);
        if (ret != ZE_SUCCESS) goto error;
        
        ZE_STREAM *s;
        ret = ze_stream_new(&s, file, len, ZE_STREAM_TYPE_FREE);
        if (ret != ZE_SUCCESS) goto error;
        
        CFDictionaryRef dict;
        ret = ze_stream_deserialize(s, (CFTypeRef *)&dict);
        if (ret != ZE_SUCCESS) goto error;
        
        NSLog(@"%@", dict);
        ze_mpq_close(mpq);
    }
    
    return self;
    
error:
    printf("%d\n", ret);
    ze_mpq_close(mpq);
    [self release];
    return nil;
}

@end
