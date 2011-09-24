#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "ze_mpq.h"

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
    
    *mpq = m;
    return ZE_SUCCESS;
error:
    free(m);
    return ret;
}

ZE_RETVAL ze_mpq_read_header(ZE_MPQ *mpq) {
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
    return ret;
}

ZE_RETVAL ze_mpq_read_user_data(ZE_MPQ *mpq) {
    ZE_RETVAL ret;
    ZE_STREAM *user_data = NULL;
    
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
    ze_stream_close(m->stream), m->stream = NULL;
    ze_mpq_close(m);
    return ret;
}

void ze_mpq_close(ZE_MPQ *mpq) {
    ze_stream_close(mpq->stream), mpq->stream = NULL;
    if (mpq->replay_info) {
        CFRelease(mpq->replay_info), mpq->replay_info = NULL;
    }
    
    free(mpq);
}