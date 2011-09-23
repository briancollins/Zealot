#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "ze_mpq.h"

ZE_RETVAL ze_mpq_new(ZE_MPQ **mpq, char *path) {
    ZE_RETVAL ret = ZE_SUCCESS;
    
    *mpq = NULL;
    ZE_MPQ *m = malloc(sizeof(ZE_MPQ));
    if (m == NULL) {
        ret = ZE_ERROR_MALLOC;
        goto error;
    }
    
    ret = ze_stream_new_file(&m->stream, path);
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    
    *mpq = m;
    ret = ze_stream_next_n(m->stream, (uint8_t *)&m->header, sizeof(ZE_MPQ_HEADER));
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    
    if (memcmp(ZE_MPQ_MAGIC, m->header.magic, 4) != 0) {
        ret = ZE_ERROR_FORMAT;
        goto error;
    }
    
    ZE_STREAM *user_data;
    ret = ze_stream_next_stream(m->stream, &user_data, m->header.user_data_length);
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    
    ret = ze_stream_deserialize(user_data, (CFTypeRef *)&m->replay_info);
    if (ret != ZE_SUCCESS) {
        goto error;
    }
    
    ze_stream_close(user_data);
    
    return ZE_SUCCESS;
    
error:
    ze_stream_close(m->stream);
    free(m);
    return ret;
}