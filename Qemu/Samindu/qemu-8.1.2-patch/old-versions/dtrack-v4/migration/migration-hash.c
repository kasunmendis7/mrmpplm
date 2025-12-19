/* Created by Samindu */
#include "migration/migration-hash.h"

int hash_digest_length;

void set_hash_digest_length(int type) {
	if (type == 0) {
		hash_digest_length = MD5_DIGEST_LENGTH;
	} else if (type == 1) {
		hash_digest_length = SHA_DIGEST_LENGTH;
	} else if (type == 2) {
                hash_digest_length = 128;
        }
}

void printh(unsigned char * hash) {
	for (int i = 0; i < SHA_DIGEST_LENGTH; i++) {
		printf("%02x", hash[i]);
	}
	printf("\n");
}


void printp(uint8_t *p, int length) {
	for(int i = 0; i < length; i++) 
		printf("%02x", p[i]);
	printf("\n");
}
/* ------------------ */
