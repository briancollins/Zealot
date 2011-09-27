#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <bzlib.h>
#include "ze_mpq.h"
#include "ze_encryption_table.h"

ZE_RETVAL ze_mpq_new(ZE_MPQ **mpq, ZE_STREAM *stream) {
    ZE_RETVAL ret = ZE_SUCCESS;
    *mpq = NULL;
    
    ZE_MPQ *m = malloc(sizeof(ZE_MPQ));
    if (m == NULL) {
        ret = ZE_ERROR_MALLOC;
        goto error;
    }
    m->stream = stream;
    m->replay_info = NULL;
    m->header = NULL;
    m->archive_header = NULL;
    
    m->hash_table = NULL;
    m->block_table = NULL;
    
    *mpq = m;
    return ZE_SUCCESS;
error:
    free(m);
    return ret;
}

ZE_RETVAL ze_mpq_read_headers(ZE_MPQ *mpq) {
    ZE_RETVAL ret;
    
    ret = ze_mpq_read_user_header(mpq);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_mpq_read_user_data(mpq);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_mpq_read_archive_header(mpq);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_mpq_read_tables(mpq);
    if (ret != ZE_SUCCESS) goto error;
    return ZE_SUCCESS;
    
error:
    return ret;
}

ZE_RETVAL ze_mpq_read_initdata(ZE_MPQ *mpq, CFStringRef *region, CFStringRef *account_id) {
    ZE_RETVAL ret;
    ZE_STREAM *s = NULL;
    CFStringRef r = NULL;
    CFStringRef a = NULL;
    
    *region = NULL;
    *account_id = NULL;
    
    ret = ze_mpq_read_file(mpq, "replay.initdata", &s);
    if (ret != ZE_SUCCESS) goto error;
    
    uint8_t n;
    ret = ze_stream_next(s, &n);
    if (ret != ZE_SUCCESS) goto error;
    
    uint8_t i;
    for (i = 0; i < n; i++) {
        uint8_t len;
        ret = ze_stream_next(s, &len);
        if (ret != ZE_SUCCESS) goto error;
        
        ret = ze_stream_skip(s, 5 + len);
        if (ret != ZE_SUCCESS) goto error;
    }
    
    ret = ze_stream_skip(s, 5);
    if (ret != ZE_SUCCESS) goto error;
    
    uint32_t *magic;
    ret = ze_stream_next_ptr(s, (uint8_t **)&magic, sizeof(uint32_t));
    
    if (ret != ZE_SUCCESS) goto error;
    if (*magic != ZE_DFLT) {
        printf("%08x\n", *magic);
        ret = ZE_ERROR_FORMAT;
        goto error;
    }
    
    ret = ze_stream_skip(s, 15);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_stream_next(s, &i);
    if (ret != ZE_SUCCESS) goto error;
    
    uint8_t *s_account_id = NULL;
    ret = ze_stream_next_ptr(s, (uint8_t **)&s_account_id, i);
    if (ret != ZE_SUCCESS) goto error;
    
    a = CFStringCreateWithBytes(NULL, (const UInt8 *)s_account_id, i, kCFStringEncodingUTF8, false);
    if (a == NULL) {
        ret = ZE_ERROR_CREATE;
        goto error;
    }
    
    ret = ze_stream_skip(s, 684);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_stream_next_ptr(s, (uint8_t **)&magic, sizeof(uint32_t));
    if (ret != ZE_SUCCESS) goto error;
    if (*magic != ZE_S2MA) {
        ret = ZE_ERROR_FORMAT;
        goto error;
    }
    
    ret = ze_stream_skip(s, 2);
    if (ret != ZE_SUCCESS) goto error;
    
    uint8_t *s_region;
    ret = ze_stream_next_ptr(s, (uint8_t **)&s_region, 2);
    if (ret != ZE_SUCCESS) goto error;
    
    r = CFStringCreateWithBytes(NULL, (const UInt8 *)s_region, 2, kCFStringEncodingUTF8, false);
    if (r == NULL) {
        ret = ZE_ERROR_CREATE;
        goto error;
    }
    
    *account_id = a;
    *region = r;
    ze_stream_close(s);
    
    return ZE_SUCCESS;
error:
    if (r != NULL) CFRelease(r), r = NULL;
    if (a != NULL) CFRelease(a), a = NULL;
    ze_stream_close(s);
    return ret;
}

ZE_RETVAL ze_mpq_read_attributes(ZE_MPQ *mpq, ZE_MPQ_ATTRIBUTE **attributes, uint32_t *n) {
    ZE_RETVAL ret;
    uint64_t build;
    ZE_STREAM *s = NULL;
    ZE_MPQ_ATTRIBUTE *attrs = NULL;
    *attributes = NULL;
    
    ret = ze_mpq_build(mpq, &build);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_mpq_read_file(mpq, "replay.attributes.events", &s);
    if (ret != ZE_SUCCESS) goto error;
    

    
    if (build < 17326)
        ret = ze_stream_skip(s, 4);
    else
        ret = ze_stream_skip(s, 5);
    
    if (ret != ZE_SUCCESS) goto error;
    
    uint32_t *count;
    
    ret = ze_stream_next_ptr(s, (uint8_t **)&count, sizeof(uint32_t));
    if (ret != ZE_SUCCESS) goto error;
    *n = *count;

    attrs = malloc(sizeof(ZE_MPQ_ATTRIBUTE) * (*count));
    if (attrs == NULL) {
        ret = ZE_ERROR_MALLOC;
        goto error;
    }
    
    ret = ze_stream_next_n(s, (uint8_t *)attrs, sizeof(ZE_MPQ_ATTRIBUTE) * (*count));
    if (ret != ZE_SUCCESS) goto error;
    
    
    ze_stream_close(s);
    *attributes = attrs;
    
    return ZE_SUCCESS;
error:
    free(attrs);
    ze_stream_close(s);
    return ret;
}

ZE_RETVAL ze_mpq_build(ZE_MPQ *mpq, uint64_t *build) {
    ZE_RETVAL ret;
    CFNumberRef n = NULL;
    if (mpq->replay_info == NULL) {
        ret = ZE_ERROR_LOAD_ORDER;
        goto error;
    }
    
    int i = 1;
    n = CFNumberCreate(NULL, kCFNumberIntType, &i);
    CFDictionaryRef d = CFDictionaryGetValue(mpq->replay_info, n);
    
    if (d == NULL || CFGetTypeID(d) != CFDictionaryGetTypeID()) {
        ret = ZE_ERROR_FORMAT;
        goto error;
    }
    
    CFRelease(n), n = NULL;
    i = 4;
    n = CFNumberCreate(NULL, kCFNumberIntType, &i);
    CFNumberRef result = CFDictionaryGetValue(d, n);
    if (result == NULL || CFGetTypeID(result) != CFNumberGetTypeID()) {
        ret = ZE_ERROR_FORMAT;
        goto error;
    }
    
    uint64_t b;
    if (!CFNumberGetValue(result, kCFNumberLongLongType, &b)) {
        ret = ZE_ERROR_FORMAT;
        goto error;
    } 
    
    *build = b;
    return ZE_SUCCESS;
    
error:
    if (n != NULL) CFRelease(n), n = NULL;
    return ret;
}

ZE_RETVAL ze_mpq_read_file(ZE_MPQ *mpq, char *filename, ZE_STREAM **s) {
    uint8_t ret;
    uint32_t hash_a, hash_b;
    uint8_t *data = NULL;
    uint8_t *uncompressed = NULL;
    
    *s = NULL;

    if (mpq->header == NULL || mpq->archive_header == NULL) {
        return ZE_ERROR_LOAD_ORDER;
    }
    
    ret = ze_mpq_hash((uint8_t *)filename, strlen(filename), ZE_MPQ_HASH_TYPE_HASH_A, &hash_a);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_mpq_hash((uint8_t *)filename, strlen(filename), ZE_MPQ_HASH_TYPE_HASH_B, &hash_b);
    if (ret != ZE_SUCCESS) goto error;
    
    uint32_t i;
    ZE_MPQ_HASH_TABLE_ENTRY *entry = NULL;
    for (i = 0; i < mpq->archive_header->hash_table_entries; i++) {
        if (mpq->hash_table[i].hash_a == hash_a &&
            mpq->hash_table[i].hash_b == hash_b) {
            entry = &mpq->hash_table[i];
            break;
        }
    }
    
    if (entry == NULL) {
        ret = ZE_ERROR_FILE_NOT_FOUND;
        goto error;
    }
    
    ZE_MPQ_BLOCK_TABLE_ENTRY *block = &(mpq->block_table[entry->block_index]);
    if (!(block->flags & ZE_BLOCK_FILE)) {
        ret = ZE_ERROR_FILE_NOT_FOUND;
        goto error;
    }
    
    if (block->flags & ZE_BLOCK_ENCRYPTED) {
        ret = ZE_ERROR_ENCRYPTED;
        goto error;
    }
    
    ret = ze_stream_seek(mpq->stream, mpq->header->archive_header_offset + block->block_offset);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_stream_next_ptr(mpq->stream, &data, block->archived_size);
    if (ret != ZE_SUCCESS) goto error;
    
    if (!(block->flags & ZE_BLOCK_SINGLE)) {
        uint32_t sector_size = 512 << mpq->archive_header->sector_size_shift;
        uint32_t sectors = block->file_size / sector_size + 1;
        uint32_t *positions = (uint32_t *)data;
        uint32_t offset = 0;
        
        size_t size = 0;
        
        uint32_t i;
        uncompressed = malloc(block->file_size);
        
        if (uncompressed == NULL) {
            ret = ZE_ERROR_MALLOC;
            goto error;
        }
        
        
        for (i = 0; i < sectors; i++) {
            uint32_t start = positions[i];
            uint32_t end = i + 1 < sectors ? positions[i + 1] : block->archived_size;
            uint32_t sector_size = end - start;
            size += sector_size;
            
            if (size > block->file_size) {
                ret = ZE_ERROR_TOO_BIG;
                goto error;
            }
            
            if (block->flags & ZE_BLOCK_COMPRESSED && block->file_size > block->archived_size) {
                uint32_t dest_len = block->file_size - offset;
                int err = BZ2_bzBuffToBuffDecompress((char *)uncompressed + offset, &dest_len, (char *)data + start + 1, sector_size, 0, 0);

                if (err != BZ_OK) {
                    ret = ZE_ERROR_BZIP;
                    goto error;
                }
                
                offset += dest_len;
            } else {
                memcpy(uncompressed, data + start, sector_size);
            }
        }
        
        ret = ze_stream_new(s, uncompressed, block->file_size, ZE_STREAM_TYPE_FREE);
        if (ret != ZE_SUCCESS) goto error;
    } else {
        if ((block->flags & ZE_BLOCK_COMPRESSED) && block->file_size > block->archived_size) {
            uint32_t dest_len = block->file_size;
            uncompressed = malloc(dest_len);
            if (uncompressed == NULL) {
                ret = ZE_ERROR_MALLOC;
                goto error;
            }
            
            int err = BZ2_bzBuffToBuffDecompress((char *)uncompressed, &dest_len, (char *)data + 1, block->archived_size - 1, 0, 0);
            
            if (err != BZ_OK) {
                ret = ZE_ERROR_BZIP;
                goto error;
            }
            ret = ze_stream_new(s, uncompressed, dest_len, ZE_STREAM_TYPE_FREE);
            if (ret != ZE_SUCCESS) goto error;
        } else {
            ret = ze_stream_new(s, data, block->archived_size, ZE_STREAM_TYPE_NONE);
            if (ret != ZE_SUCCESS) goto error;
        }
    }
    
    return ZE_SUCCESS;
    
error:
    free(uncompressed);
    if (*s != NULL) {
        ze_stream_close(*s);    
        *s = NULL;
    }
    
    return ret;
}

ZE_RETVAL ze_mpq_read_tables(ZE_MPQ *mpq) {
    ZE_RETVAL ret;
    
    if (mpq->archive_header == NULL) {
        ret = ZE_ERROR_LOAD_ORDER;
        goto error;
    }
    
    ret = ze_mpq_read_table(mpq, mpq->header->archive_header_offset + mpq->archive_header->hash_table_offset, mpq->archive_header->hash_table_entries, (uint8_t **)&mpq->hash_table, "(hash table)");
    
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_mpq_read_table(mpq, mpq->header->archive_header_offset + mpq->archive_header->block_table_offset, mpq->archive_header->block_table_entries, (uint8_t **)&mpq->block_table, "(block table)");
    
    if (ret != ZE_SUCCESS) goto error;

    
    return ZE_SUCCESS;
error:
    return ret;
}

ZE_RETVAL ze_mpq_hash(uint8_t *str, size_t len, ZE_MPQ_HASH_TYPE hash_type, uint32_t *hash) {
    size_t i;
    
    uint32_t seed1 = 0x7FED7FED;
    uint32_t seed2 = 0xEEEEEEEE;
    uint32_t ht = hash_type;
    
    for (i = 0; i < len; i++) {
        uint8_t c = toupper(str[i]);
        seed1 = encryption_table[(ht << 8) + c] ^ (seed1 + seed2);
        seed2 = c + seed1 + seed2 + (seed2 << 5) + 3;
    }
    
    *hash = seed1;
    return ZE_SUCCESS;
}

ZE_RETVAL ze_mpq_decrypt(uint32_t *dwords, off_t len, uint32_t seed1) {
    uint32_t seed2 = 0xEEEEEEEE;
    off_t i;
    for (i = 0; i < len; i++) {
        seed2 += encryption_table[0x400 + (seed1 & 0xFF)];
        dwords[i] ^= (seed1 + seed2);
        seed1 = ((~seed1 << 0x15) + 0x11111111) | (seed1 >> 0x0B);
        seed2 = dwords[i] + seed2 + (seed2 << 5) + 3;
    }
    
    return ZE_SUCCESS;
}

ZE_RETVAL ze_mpq_read_table(ZE_MPQ *mpq, uint32_t offset, uint32_t count, uint8_t **bytes, char *key) {
    ZE_RETVAL ret = ZE_SUCCESS;
    uint8_t *data = NULL;
    *bytes = NULL;

    ret = ze_stream_seek(mpq->stream, offset);
    if (ret != ZE_SUCCESS) goto error;
    
    size_t len = count * 16;
    
    data = malloc(len);
    if (data == NULL) {
        ret = ZE_ERROR_MALLOC;
        goto error;
    }
    
    ret = ze_stream_next_n(mpq->stream, data, len);
    if (ret != ZE_SUCCESS) goto error;
    
    uint32_t hash;
    ret = ze_mpq_hash((uint8_t *)key, strlen(key), ZE_MPQ_HASH_TYPE_TABLE, &hash);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_mpq_decrypt((uint32_t *)data, len / 4, hash);
    if (ret != ZE_SUCCESS) goto error;
    
    *bytes = data;
    
    return ZE_SUCCESS;
error:
    free(data);
    *bytes = NULL;
    return ret;
}

ZE_RETVAL ze_mpq_read_user_header(ZE_MPQ *mpq) {
    ZE_RETVAL ret;
    ret = ze_stream_seek(mpq->stream, 0);
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    
    ret = ze_stream_next_ptr(mpq->stream, (uint8_t **)&mpq->header, sizeof(ZE_MPQ_HEADER));
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    
    if (memcmp(ZE_MPQ_MAGIC, mpq->header->magic, 4) != 0) {
        ret = ZE_ERROR_FORMAT;
        goto error;
    }
    
    return ZE_SUCCESS;
error:
    mpq->header = NULL;
    return ret;
}

ZE_RETVAL ze_mpq_read_archive_header(ZE_MPQ *mpq) {
    ZE_RETVAL ret;
    
    if (mpq->header == NULL) {
        ret = ZE_ERROR_LOAD_ORDER;
        goto error;
    }
    
    ret = ze_stream_seek(mpq->stream, mpq->header->archive_header_offset);
    if (ret != ZE_SUCCESS) goto error;
    
    ret = ze_stream_next_ptr(mpq->stream, (uint8_t **)&mpq->archive_header, sizeof(ZE_MPQ_ARCHIVE_HEADER));
    if (ret != ZE_SUCCESS) goto error;
    
    if (memcmp(ZE_MPQ_ARCHIVE_MAGIC, mpq->archive_header->magic, 4) != 0) {
        ret = ZE_ERROR_FORMAT;
        goto error;
    }
    
    return ZE_SUCCESS;
error:
    mpq->archive_header = NULL;
    return ret;
}

ZE_RETVAL ze_mpq_read_user_data(ZE_MPQ *mpq) {
    ZE_RETVAL ret;
    ZE_STREAM *user_data = NULL;
    
    if (mpq->header == NULL) {
        ret = ZE_ERROR_LOAD_ORDER;
        goto error;
    }
    
    ret = ze_stream_seek(mpq->stream, sizeof(ZE_MPQ_HEADER));
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    
    ret = ze_stream_next_stream(mpq->stream, &user_data, mpq->header->user_data_length);    
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    
    ret = ze_stream_deserialize(user_data, (CFTypeRef *)&mpq->replay_info);
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    ze_stream_close(user_data);
    
    return ZE_SUCCESS;
error:
    if (mpq->replay_info != NULL) {
        CFRelease(mpq->replay_info), mpq->replay_info = NULL;
    }
    
    ze_stream_close(user_data);
    return ret;
}

ZE_RETVAL ze_mpq_new_file(ZE_MPQ **mpq, char *path) {
    ZE_RETVAL ret = ZE_SUCCESS;
    ZE_MPQ *m = NULL;
    
    *mpq = NULL;
    
    ZE_STREAM *stream;
    ret = ze_stream_new_file(&stream, path);
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    

    ret = ze_mpq_new(&m, stream);
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    
    *mpq = m;
    
    return ZE_SUCCESS;
    
error:
    if (m != NULL) {
        ze_stream_close(m->stream), m->stream = NULL;
        ze_mpq_close(m);
    }

    return ret;
}

void ze_mpq_close(ZE_MPQ *mpq) {
    ze_stream_close(mpq->stream), mpq->stream = NULL;
    if (mpq->replay_info) {
        CFRelease(mpq->replay_info), mpq->replay_info = NULL;
    }
    
    free(mpq->hash_table), mpq->hash_table = NULL;
    free(mpq->block_table), mpq->block_table = NULL;
    
    free(mpq);
}