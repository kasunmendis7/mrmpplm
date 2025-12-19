/* Created by Samindu */
#ifndef MIGRATION_HASH
#define MIGRATION_HASH

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <openssl/sha.h>
#include <openssl/md5.h>
#include "murmur3.h"

void set_hash_digest_length(int type);
void printh(unsigned char *hash);
void printp(uint8_t *p, int length);

extern int hash_digest_length;
extern int iteration;
extern bool last_stage;
extern int64_t *page_count;
extern int64_t *fake_dirty;

#endif
/* -------------------- */
