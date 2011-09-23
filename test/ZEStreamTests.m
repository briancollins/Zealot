#import "ZEStreamTests.h"
#import "ze_stream.h"

@implementation ZEStreamTests

- (void)testStreamNew {
    ZE_STREAM *s;
    uint8_t bytes[] = {'t', 'e', 's', 't'};
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 4, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    ze_stream_close(s);
}

- (void)testStreamNext {
    ZE_STREAM *s;
    uint8_t bytes[] = {'t'};
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 1, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    
    uint8_t byte;
    ret = ze_stream_next(s, &byte);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success reading a byte");
    STAssertEquals(byte, (uint8_t)'t', @"Should read the correct byte");
    
    ret = ze_stream_next(s, &byte);
    STAssertEquals(ret, ZE_ERROR_UNEXPECTED_EOF, @"Should fail when at end of stream");
    ze_stream_close(s);
}

- (void)testStreamPeek {
    ZE_STREAM *s;
    uint8_t bytes[] = {'t'};
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 1, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");    
    
    uint8_t byte;
    ret = ze_stream_peek(s, &byte);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success peeking a byte");
    STAssertEquals(byte, (uint8_t)'t', @"Should peek the correct byte");
    
    ret = ze_stream_next(s, &byte);
    STAssertEquals(ret, ZE_SUCCESS, @"Should read a byte sucessfully after peeking");
    
    ret = ze_stream_peek(s, &byte);
    STAssertEquals(ret, ZE_ERROR_UNEXPECTED_EOF, @"Should fail peeking a byte");    
    ze_stream_close(s);
}

- (void)testStreamSkip {
    ZE_STREAM *s;
    uint8_t bytes[] = {'t', 'e', 's', 't'};
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 4, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    
    uint8_t byte;
    ret = ze_stream_skip(s, 1);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success skipping a byte");
    
    ret = ze_stream_peek(s, &byte);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success peeking a byte");
    STAssertEquals(byte, (uint8_t)'e', @"Should peek the correct byte");
    
    ret = ze_stream_skip(s, 4);
    STAssertEquals(ret, ZE_ERROR_UNEXPECTED_EOF, @"Should fail skipping too far");
    
    ret = ze_stream_peek(s, &byte);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success peeking a byte");
    STAssertEquals(byte, (uint8_t)'e', @"Should peek the correct byte");
    
    ret = ze_stream_skip(s, 3);
    STAssertEquals(ret, ZE_SUCCESS, @"Should be able to skip to the end");
    
    ret = ze_stream_peek(s, &byte);
    STAssertEquals(ret, ZE_ERROR_UNEXPECTED_EOF, @"Should fail peeking a byte");    
    ze_stream_close(s);
}

- (void)testStreamNextN {
    ZE_STREAM *s;
    uint8_t bytes[] = {'t', 'e', 's', 't'};
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 4, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");

    uint8_t buf[5] = {'\0'};
    ret = ze_stream_next_n(s, (uint8_t *)&buf, 5);
    STAssertEquals(ret, ZE_ERROR_UNEXPECTED_EOF, @"Should fail getting next 5 bytes from a 4 byte stream");
    
    ret = ze_stream_next_n(s, (uint8_t *)&buf, 4);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success getting next 4 bytes");
    STAssertEquals(0, memcmp(buf, bytes, 4), @"Should fill buffer with bytes from stream");

    ret = ze_stream_next_n(s, (uint8_t *)&buf, 1);
    STAssertEquals(ret, ZE_ERROR_UNEXPECTED_EOF, @"Should be no bytes left to copy");
    
    ze_stream_close(s);
}

- (void)testStreamDeserializeString {
    ZE_STREAM *s;
    uint8_t bytes[] = {0x02, 0x05 << 1, 'h', 'e', 'l', 'l', 'o'};
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 7, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    
    CFTypeRef r = NULL;
    ret = ze_stream_deserialize(s, &r);
    STAssertEquals(ret, ZE_SUCCESS, @"Should successfully deserialize a string");
    STAssertEqualObjects(@"hello", (NSString *)r, @"Should return correct string");

    if (r) CFRelease(r);
    
    bytes[1] = 0x06 << 1;
    s->cursor = 0; // rewind stream
    
    r = NULL;
    ret = ze_stream_deserialize(s, &r);
    STAssertEquals(ret, ZE_ERROR_UNEXPECTED_EOF, @"Should fail when string length is longer than stream");
    STAssertEquals((void *)r, NULL, @"Should set string to NULL");
    
    if (r) CFRelease(r);
    
    ze_stream_close(s);    
}

- (void)testStreamDeserializeArray {
    ZE_STREAM *s;
    uint8_t bytes[] = {
        0x04, 0x00, 0x00, 0x02 << 1, 
        0x02, 0x05 << 1, 'h', 'e', 'l', 'l', 'o',
        0x02, 0x05 << 1, 'w', 'o', 'r', 'l', 'd',
    };
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 18, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    CFTypeRef r = NULL;
    ret = ze_stream_deserialize(s, &r);
    STAssertEquals(ret, ZE_SUCCESS, @"Should successfully deserialize an array");
    NSArray *arr = [NSArray arrayWithObjects:@"hello", @"world", nil];
    STAssertEqualObjects(arr, (NSArray *)r, @"Should return correct array");
    
    if (r) CFRelease(r);
    
    ze_stream_close(s);
}

- (void)testStreamDeserializeDictionary {
    ZE_STREAM *s;
    uint8_t bytes[] = {
        0x05, 0x02 << 1, 
        0x01 << 1,
        0x02, 0x05 << 1, 'h', 'e', 'l', 'l', 'o',
        0x02 << 1,
        0x02, 0x05 << 1, 'w', 'o', 'r', 'l', 'd',
    };
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 18, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    CFTypeRef r = NULL;
    ret = ze_stream_deserialize(s, &r);
    STAssertEquals(ret, ZE_SUCCESS, @"Should successfully deserialize a dictionary");
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"hello", [NSNumber numberWithInt:1],
                    @"world", [NSNumber numberWithInt:2], nil];
    STAssertEqualObjects(d, (NSDictionary *)r, @"Should return correct dictionary");
    
    if (r) CFRelease(r);
    
    ze_stream_close(s);
}

- (void)testStreamDeserializeByte {
    ZE_STREAM *s;
    uint8_t bytes[] = {
        0x06, 42 << 1, 
    };
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 2, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    CFTypeRef r = NULL;
    ret = ze_stream_deserialize(s, &r);
    STAssertEquals(ret, ZE_SUCCESS, @"Should successfully deserialize a byte");
    NSNumber *n = [NSNumber numberWithInt:42];
    STAssertEqualObjects(n, (NSNumber *)r, @"Should return correct number");
    
    if (r) CFRelease(r);
    
    ze_stream_close(s);
}


- (void)testStreamDeserializeDword {
    ZE_STREAM *s;
    uint8_t bytes[] = {
        0x07, 0x12, 0x34, 0x56, 0x78
    };
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 5, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    CFTypeRef r = NULL;
    ret = ze_stream_deserialize(s, &r);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success deserializing a dword");
    
    NSNumber *n = [NSNumber numberWithUnsignedLong:0x78563412];
    STAssertEqualObjects(n, (NSNumber *)r, @"Should return correct number");
    
    if (r) CFRelease(r);
    ze_stream_close(s);
}

- (void)testStreamDeserializeVarInt {
    ZE_STREAM *s;
    uint8_t bytes[] = {
        0x09, 0xf2, 0xbf, 0x50
    };
    ZE_RETVAL ret = ze_stream_new(&s, bytes, 4, ZE_STREAM_TYPE_NONE);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success creating a stream");
    CFTypeRef r = NULL;
    ret = ze_stream_deserialize(s, &r);
    STAssertEquals(ret, ZE_SUCCESS, @"Should return success deserializing a var int");

    NSNumber *n = [NSNumber numberWithLong:659449];
    STAssertEqualObjects(n, (NSNumber *)r, @"Should return correct number");
    
    if (r) CFRelease(r);
    ze_stream_close(s);
}

@end
