#import "ZEMPQTests.h"
#import "ze_mpq.h"

@implementation ZEMPQTests

- (void)testMPQNew {
    ZE_STREAM *s;
    uint8_t bytes[] = {};
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 0, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    
    ZE_MPQ *mpq;
    ret = ze_mpq_new(&mpq, s);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating an mpq");
    ze_mpq_close(mpq);    
}

- (void)testMPQHeader {
    ZE_STREAM *s;
    uint8_t bytes[] = {
        'M', 'P', 'Q', '\x1b',
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00
    };
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 16, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    
    ZE_MPQ *mpq;
    ret = ze_mpq_new(&mpq, s);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating an mpq");
    
    ret = ze_mpq_read_user_header(mpq);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success reading header");
    
    ze_mpq_close(mpq);
}

- (void)testMPQInvalidHeader {
    ZE_STREAM *s;
    uint8_t bytes[] = {
        'M', 'X', 'Q', '\x1b',
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00
    };
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 16, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    
    ZE_MPQ *mpq;
    ret = ze_mpq_new(&mpq, s);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating an mpq");
    
    ret = ze_mpq_read_user_header(mpq);
    STAssertEquals(ret, ZE_ERROR_FORMAT, @"Should return bad format reading header");
    
    ze_mpq_close(mpq);
}

- (void)testMPQUserData {
    ZE_STREAM *s;
    uint8_t bytes[] = {
        'M', 'P', 'Q', '\x1b',
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x12, 0x00, 0x00, 0x00,
        0x05, 0x02 << 1, 
        0x01 << 1,
        0x02, 0x05 << 1, 'h', 'e', 'l', 'l', 'o',
        0x02 << 1,
        0x02, 0x05 << 1, 'w', 'o', 'r', 'l', 'd'
    };
    
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 34, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    
    ZE_MPQ *mpq;
    ret = ze_mpq_new(&mpq, s);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating an mpq");
    
    ret = ze_mpq_read_user_header(mpq);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success reading header");
    
    ret = ze_mpq_read_user_data(mpq);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success reading user data");
    
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"hello", [NSNumber numberWithInt:1],
                       @"world", [NSNumber numberWithInt:2], nil];
    STAssertEqualObjects(d, (NSDictionary *)mpq->replay_info, @"Should return correct replay info");
    
    ze_mpq_close(mpq);
}

- (NSString *)fixturePath:(NSString *)name {
    return [[[[NSBundle bundleForClass:[self class]] resourcePath] 
            stringByAppendingPathComponent:@"fixtures"]
            stringByAppendingPathComponent:name];
}

- (void)testMPQBlockExtraction {
    ZE_MPQ *mpq;
    ZE_RETVAL ret;
    const char *path = [[self fixturePath:@"starjeweled.SC2Replay"] UTF8String];
    ret = ze_mpq_new_file(&mpq, (char *)path);
    STAssertEquals(ret, ZE_SUCCESS, @"Should open replay fixture");
    
    ret = ze_mpq_read_headers(mpq);
    STAssertEquals(ret, ZE_SUCCESS, @"Should read replay headers");
    
    NSString *folder = [self fixturePath:@"starjeweled"];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:NULL];
    
    for (NSString *file in files) {
        NSData *d = [NSData dataWithContentsOfFile:[folder stringByAppendingPathComponent:file]];

        ZE_STREAM *s;
        ret = ze_mpq_read_file(mpq, (char *)[file UTF8String], &s);
        STAssertEquals(ret, ZE_SUCCESS, @"Should get file contents for %@", file);
        
        NSData *d2 = [NSData dataWithBytes:s->bytes length:s->len];
        
        STAssertTrue([d isEqualToData:d2], @"Should have the same data for %@", file);
        /* because STAssertEqualObjects will print out the entire NSData contents on fail */
        
        ze_stream_close(s);
    }
    
    ze_mpq_close(mpq);
}

- (void)testMPQInitData {
    ZE_MPQ *mpq;
    ZE_RETVAL ret;
    const char *path = [[self fixturePath:@"starjeweled.SC2Replay"] UTF8String];
    ret = ze_mpq_new_file(&mpq, (char *)path);
    STAssertEquals(ret, ZE_SUCCESS, @"Should open replay fixture");

    ret = ze_mpq_read_headers(mpq);
    STAssertEquals(ret, ZE_SUCCESS, @"Should read replay headers");

    CFStringRef account_id;
    CFStringRef region;
    ze_mpq_read_initdata(mpq, &region, &account_id);
    STAssertEquals(ret, ZE_SUCCESS, @"Should read initdata");
    
    STAssertEqualObjects((NSString *)account_id, @"2-S2-1-165251", @"Should have correct account ID");
    STAssertEqualObjects((NSString *)region, @"EU", @"Should have correct account ID");
    CFRelease(account_id);
    CFRelease(region);
    
    ze_mpq_close(mpq);
}

@end
