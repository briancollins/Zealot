#ifndef _ze_mpq_h_
#define _ze_mpq_h_
#include <CoreFoundation/CoreFoundation.h>
#include "ze_stream.h"

#define ZE_MPQ_MAGIC "MPQ\x1b"
#define ZE_MPQ_ARCHIVE_MAGIC "MPQ\x1a"
#define ZE_MPQ_SEED_1 0x7FED7FED
#define ZE_MPQ_SEED_2 0xEEEEEEEE
#define ZE_MPQ_HASH_ENTRY_EMPTY 0xFFFFFFFF
#define ZE_MPQ_HASH_ENTRY_DELETED 0xFFFFFFFE
#define ZE_DFLT 0x746c6644
#define ZE_S2MA 0x616D3273

#pragma pack(push)
#pragma pack(1)
typedef struct {
    uint8_t magic[4];
    uint32_t user_data_max_length;
    uint32_t archive_header_offset;
    uint32_t user_data_length;
} ZE_MPQ_HEADER;

typedef struct {
    uint8_t magic[4];
    uint32_t header_size;
    uint32_t archive_size;
    uint16_t format_version;
    uint8_t sector_size_shift;
    uint8_t unknown;
    uint32_t hash_table_offset;
    uint32_t block_table_offset;
    uint32_t hash_table_entries;
    uint32_t block_table_entries;
    uint64_t extended_block_table_offset;
    uint16_t hash_table_offset_high;
    uint16_t block_table_offset_high;
} ZE_MPQ_ARCHIVE_HEADER;

typedef struct {
    uint32_t hash_a;
    uint32_t hash_b;
    uint16_t language;
    uint8_t platform;
    uint8_t unknown;
    uint32_t block_index;
} ZE_MPQ_HASH_TABLE_ENTRY;

typedef struct {
    uint32_t block_offset;
    uint32_t archived_size;
    uint32_t file_size;
    uint32_t flags;
} ZE_MPQ_BLOCK_TABLE_ENTRY;

typedef struct {
    uint32_t header;
    uint32_t attribute_id;
    uint8_t player;
    uint8_t str[4];
} ZE_MPQ_ATTRIBUTE;
#pragma pack(pop)

typedef struct {
    ZE_STREAM *stream;
    char **filenames;
    ZE_MPQ_HEADER *header;
    ZE_MPQ_ARCHIVE_HEADER *archive_header;
    CFDictionaryRef replay_info;
    ZE_MPQ_HASH_TABLE_ENTRY *hash_table;
    ZE_MPQ_BLOCK_TABLE_ENTRY *block_table;
} ZE_MPQ;

typedef enum {
    ZE_MPQ_HASH_TYPE_TABLE_OFFSET = 0,
    ZE_MPQ_HASH_TYPE_HASH_A = 1,
    ZE_MPQ_HASH_TYPE_HASH_B = 2,
    ZE_MPQ_HASH_TYPE_TABLE = 3
} ZE_MPQ_HASH_TYPE;

typedef enum {
    ZE_BLOCK_FILE       = 0x80000000,
    ZE_BLOCK_COMPRESSED = 0x00000200,
    ZE_BLOCK_ENCRYPTED  = 0x00010000,
    ZE_BLOCK_SINGLE     = 0x01000000,
    ZE_BLOCK_CRC        = 0x04000000
} ZE_BLOCK_FLAGS;

ZE_RETVAL ze_mpq_new(ZE_MPQ **mpq, ZE_STREAM *stream);
ZE_RETVAL ze_mpq_build(ZE_MPQ *mpq, uint64_t *build);
ZE_RETVAL ze_mpq_new_file(ZE_MPQ **mpq, char *path);
ZE_RETVAL ze_mpq_read_user_header(ZE_MPQ *mpq);
ZE_RETVAL ze_mpq_read_archive_header(ZE_MPQ *mpq);
ZE_RETVAL ze_mpq_read_user_data(ZE_MPQ *mpq);
ZE_RETVAL ze_mpq_read_table(ZE_MPQ *mpq, uint32_t offset, uint32_t count, uint8_t **bytes, char *key);
ZE_RETVAL ze_mpq_decrypt(uint32_t *dwords, off_t len, uint32_t seed1);
ZE_RETVAL ze_mpq_hash(uint8_t *str, size_t len, ZE_MPQ_HASH_TYPE hash_type, uint32_t *hash);
ZE_RETVAL ze_mpq_read_tables(ZE_MPQ *mpq);
ZE_RETVAL ze_mpq_read_file(ZE_MPQ *mpq, char *filename, ZE_STREAM **s);
ZE_RETVAL ze_mpq_read_headers(ZE_MPQ *mpq);
ZE_RETVAL ze_mpq_read_initdata(ZE_MPQ *mpq, CFStringRef *region, CFStringRef *account_id);
ZE_RETVAL ze_mpq_read_attributes(ZE_MPQ *mpq, CFArrayRef *attributes);

void ze_mpq_close(ZE_MPQ *mpq);

#endif
