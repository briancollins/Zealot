#ifndef _ze_mpq_h_
#define _ze_mpq_h_
#include <CoreFoundation/CoreFoundation.h>
#include "ze_stream.h"

#define ZE_MPQ_MAGIC "MPQ\x1b"

#pragma pack(push)
#pragma pack(1)
typedef struct {
    uint8_t magic[4];
    uint32_t user_data_max_length;
    uint32_t archive_header_offset;
    uint32_t user_data_length;
} ZE_MPQ_HEADER;
#pragma pack(pop)

typedef struct {
    ZE_STREAM *stream;
    char **filenames;
    ZE_MPQ_HEADER header;
    CFDictionaryRef replay_info;
} ZE_MPQ;


ZE_RETVAL ze_mpq_new(ZE_MPQ **mpq, char *path);

#endif
