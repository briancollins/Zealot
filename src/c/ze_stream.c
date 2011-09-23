#include <stdlib.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include "ze_stream.h"

ZE_RETVAL ze_stream_new(ZE_STREAM **stream, uint8_t *bytes, size_t len, ZE_STREAM_TYPE type) {
    *stream = NULL;
    
    ZE_STREAM *s = malloc(sizeof(ZE_STREAM));
    
    if (s == NULL) {
        return ZE_ERROR_MALLOC;
    }
    
    s->len = len;
    s->bytes = bytes;
    s->type = type;
    s->cursor = 0;
    *stream = s;
    
    return ZE_SUCCESS;
}

ZE_RETVAL ze_stream_new_file(ZE_STREAM **stream, char *path) {
    *stream = NULL;
    int fd = open(path, O_RDONLY);
    
    if (fd == -1) {
        return ZE_ERROR_OPEN;
    }
    
    struct stat statbuf;
    
    if (fstat(fd, &statbuf) == -1) {
        return ZE_ERROR_STAT;
    }
    
    uint8_t *map = mmap(0, statbuf.st_size, PROT_READ, MAP_SHARED, fd, 0);
    
    if (map == MAP_FAILED) {
        return ZE_ERROR_MMAP;
    }
    
    ZE_STREAM *s;
    ZE_RETVAL ret = ze_stream_new(&s, map, statbuf.st_size, ZE_STREAM_TYPE_FILE);
    if (ret != ZE_SUCCESS) {
        munmap(map, statbuf.st_size);
        return ret;
    }
    
    *stream = s;
    
    return ZE_SUCCESS;
}

void ze_stream_close(ZE_STREAM *stream) { 
    if (stream == NULL) {
        return;
    }
    
    if (stream->type == ZE_STREAM_TYPE_FILE) {
        munmap(stream->bytes, stream->len);
        
    } else if (stream->type == ZE_STREAM_TYPE_FREE) {
        free(stream->bytes);
    }
    
    free(stream);
}

ZE_RETVAL ze_stream_skip(ZE_STREAM *stream, size_t len) {
    if (stream->cursor + len > stream->len) {
        return ZE_ERROR_UNEXPECTED_EOF;
    }
    
    stream->cursor += len;
    return ZE_SUCCESS;
}

ZE_RETVAL ze_stream_next(ZE_STREAM *stream, uint8_t *byte) {
    if (stream->cursor + 1 > stream->len) {
        return ZE_ERROR_UNEXPECTED_EOF;
    }
    
    *byte = stream->bytes[stream->cursor++];
    return ZE_SUCCESS;
}

ZE_RETVAL ze_stream_peek(ZE_STREAM *stream, uint8_t *byte) {
    if (stream->cursor + 1 > stream->len) {
        return ZE_ERROR_UNEXPECTED_EOF;
    }
    
    *byte = stream->bytes[stream->cursor];
    return ZE_SUCCESS;
}

ZE_RETVAL ze_stream_next_n(ZE_STREAM *stream, uint8_t *buf, size_t len) {
    if (stream->cursor + len > stream->len) {
        return ZE_ERROR_UNEXPECTED_EOF;
    }
    
    memcpy(buf, stream->bytes + stream->cursor, len);
    stream->cursor += len;
    return ZE_SUCCESS;
}

ZE_RETVAL ze_stream_next_ptr(ZE_STREAM *stream, uint8_t **ptr, size_t len) {
    uint8_t *p = stream->bytes + stream->cursor;
    ZE_RETVAL ret = ze_stream_skip(stream, len);
    if (ret == ZE_SUCCESS) {
        *ptr = p;
    }
    
    return ret;
}

ZE_RETVAL ze_stream_next_string(ZE_STREAM *stream, CFStringRef *str, size_t len) {
    uint8_t *ptr = NULL;
    ZE_RETVAL ret = ze_stream_next_ptr(stream, &ptr, len);
    if (ret != ZE_SUCCESS) {
        return ret;
    }
    
    *str = CFStringCreateWithBytes(NULL, ptr, len, kCFStringEncodingUTF8, false);
    if (*str == NULL) {
        return ZE_ERROR_CREATE;
    }
    return ZE_SUCCESS;
}

ZE_RETVAL ze_stream_next_var_int(ZE_STREAM *stream, int64_t *var_int) {
    ZE_RETVAL ret;
    uint8_t byte;
    int count = 0;
    
    ret = ze_stream_peek(stream, &byte);
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    *var_int = byte & 0x7f;
    
    while (1) {
        ret = ze_stream_next(stream, &byte);
        if (ret != ZE_SUCCESS) goto error;
        if ((byte & 0x80) == 0) break;
        
        ret = ze_stream_peek(stream, &byte);
        if (ret != ZE_SUCCESS) goto error;
        uint64_t next = byte & 0x7f;
        *var_int += next << (7 * ++count);
    }
    
    *var_int = pow(-1, *var_int & 0x1) * (*var_int >> 1);
    return ZE_SUCCESS;
    
error:
    return ret;
}

ZE_RETVAL ze_stream_deserialize(ZE_STREAM *stream, CFTypeRef *type_ref) {
    ZE_RETVAL ret;
    uint8_t byte, len;
    int64_t long_len;
    int64_t i;
    int32_t dword;
    *type_ref = NULL;
    
    ret = ze_stream_next(stream, &byte);
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    
    switch(byte) {
        case 0x02:
            ret = ze_stream_next(stream, &len);
            if (ret != ZE_SUCCESS) goto error;
            len >>= 1;
            ret = ze_stream_next_string(stream, (CFStringRef *)type_ref, len);
            if (ret != ZE_SUCCESS) goto error;
            break;
            
        case 0x04:
            ret = ze_stream_skip(stream, 2);
            if (ret != ZE_SUCCESS) goto error;
            ret = ze_stream_next_var_int(stream, &long_len);
            if (ret != ZE_SUCCESS) goto error;
            *type_ref = CFArrayCreateMutable(NULL, long_len, &kCFTypeArrayCallBacks);
            if (*type_ref == NULL) {
                ret = ZE_ERROR_CREATE;
                goto error;
            }
            
            for (i = 0; i < long_len; i++) {
                CFTypeRef ref;
                ret = ze_stream_deserialize(stream, &ref);
                if (ret != ZE_SUCCESS) goto error;
                CFArrayAppendValue((CFMutableArrayRef)*type_ref, ref);
                CFRelease(ref);
            }
            break;
        case 0x05:
            ret = ze_stream_next_var_int(stream, &long_len);
            if (ret != ZE_SUCCESS) goto error;
            *type_ref = CFDictionaryCreateMutable(NULL, long_len, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            if (*type_ref == NULL) {
                ret = ZE_ERROR_CREATE;
                goto error;
            }
            
            for (i = 0; i < long_len; i++) {
                CFNumberRef key = NULL;
                int64_t next_num;
                ret = ze_stream_next_var_int(stream, &next_num);
                if (ret != ZE_SUCCESS) goto error;
                key = CFNumberCreate(NULL, kCFNumberLongLongType, &next_num);
                if (key == NULL) {
                    ret = ZE_ERROR_CREATE;
                    goto error;
                }
                
                CFTypeRef value = NULL;
                ret = ze_stream_deserialize(stream, &value);
                if (ret != ZE_SUCCESS) goto error;
                
                CFDictionarySetValue((CFMutableDictionaryRef)*type_ref, key, value);
                CFRelease(key);
                CFRelease(value);
            }
            break;
        case 0x06:
            ret = ze_stream_next(stream, &byte);
            int x = byte;
            if (ret != ZE_SUCCESS) goto error;
            *type_ref = CFNumberCreate(NULL, kCFNumberIntType, &x);
            if (*type_ref == NULL) {
                ret = ZE_ERROR_CREATE;
                goto error;
            }
            break;
        case 0x07:
            ret = ze_stream_next_n(stream, (uint8_t *)&dword, sizeof(dword));
            if (ret != ZE_SUCCESS) goto error;
            
            *type_ref = CFNumberCreate(NULL, kCFNumberIntType, &dword);
            if (*type_ref == NULL) {
                ret = ZE_ERROR_CREATE;
                goto error;
            }
            break;
        case 0x09:
            ret = ze_stream_next_var_int(stream, &long_len);
            if (ret != ZE_SUCCESS) goto error;
            
            *type_ref = CFNumberCreate(NULL, kCFNumberLongLongType, &long_len);
            if (*type_ref == NULL) {
                ret = ZE_ERROR_CREATE;
                goto error;
            }
            
            break;
        default:
            ret = ZE_ERROR_FORMAT;
            goto error;
    }
    
    return ZE_SUCCESS;
        
    error:
    if (*type_ref != NULL) {
        CFRelease(*type_ref), *type_ref = NULL;
    }
    return ret;
}

ZE_RETVAL ze_stream_next_stream(ZE_STREAM *stream, ZE_STREAM **s, size_t len) {
    ZE_RETVAL ret;
    uint8_t *ptr;
    ret = ze_stream_next_ptr(stream, &ptr, len);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_stream_new(s, ptr, len, ZE_STREAM_TYPE_NONE);
    if (ret != ZE_SUCCESS) goto error;
    
    return ZE_SUCCESS;
error:
    ze_stream_close(*s);
    return ret;
}