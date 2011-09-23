#ifndef _ze_stream_h_
#define _ze_stream_h_
#include <sys/types.h>
#include <stdint.h>
#include <CoreFoundation/CoreFoundation.h>

typedef enum {
    ZE_STREAM_TYPE_NONE,
    ZE_STREAM_TYPE_FILE,
    ZE_STREAM_TYPE_FREE
} ZE_STREAM_TYPE;

typedef struct {
    uint8_t *bytes;
    
    off_t cursor;
    
    size_t len;
    ZE_STREAM_TYPE type;
} ZE_STREAM;

typedef enum {
    ZE_SUCCESS = 0,
    ZE_ERROR_OPEN,
    ZE_ERROR_STAT,
    ZE_ERROR_MALLOC,
    ZE_ERROR_MMAP,
    ZE_ERROR_FORMAT,
    ZE_ERROR_UNEXPECTED_EOF,
    ZE_ERROR_CREATE
} ZE_RETVAL;

ZE_RETVAL ze_stream_new(ZE_STREAM **stream, uint8_t *bytes, size_t len, ZE_STREAM_TYPE type);
ZE_RETVAL ze_stream_new_file(ZE_STREAM **stream, char *path);
void ze_stream_close(ZE_STREAM *stream);
ZE_RETVAL ze_stream_skip(ZE_STREAM *stream, size_t len);
ZE_RETVAL ze_stream_next(ZE_STREAM *stream, uint8_t *byte);
ZE_RETVAL ze_stream_peek(ZE_STREAM *stream, uint8_t *byte);
ZE_RETVAL ze_stream_next_n(ZE_STREAM *stream, uint8_t *buf, size_t len);
ZE_RETVAL ze_stream_deserialize(ZE_STREAM *stream, CFTypeRef *dict);
ZE_RETVAL ze_stream_next_string(ZE_STREAM *stream, CFStringRef *str, size_t len);
ZE_RETVAL ze_stream_next_var_int(ZE_STREAM *stream, int64_t *var_int);
ZE_RETVAL ze_stream_next_stream(ZE_STREAM *stream, ZE_STREAM **s, size_t len);

#endif
