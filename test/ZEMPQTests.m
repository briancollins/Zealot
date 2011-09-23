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
    
    ret = ze_mpq_read_header(mpq);
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
    
    ret = ze_mpq_read_header(mpq);
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
    
    ret = ze_mpq_read_header(mpq);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success reading header");
    
    ret = ze_mpq_read_user_data(mpq);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success reading user data");
    
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"hello", [NSNumber numberWithInt:1],
                       @"world", [NSNumber numberWithInt:2], nil];
    STAssertEqualObjects(d, (NSDictionary *)mpq->replay_info, @"Should return correct replay info");
    
    ze_mpq_close(mpq);
}

@end
