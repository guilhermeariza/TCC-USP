#ifndef LSM_H
#define LSM_H

#include <stdint.h>
#include <stddef.h>
#include <stdatomic.h>

extern _Atomic uint64_t physical_bytes_written;
extern _Atomic uint64_t logical_bytes_written;

typedef struct LSMTree LSMTree;

LSMTree* lsm_create(size_t threshold, const char* data_dir);
void lsm_insert(LSMTree* tree, uint64_t key, uint64_t value);
uint64_t* lsm_search(LSMTree* tree, uint64_t key); // Ret ptr to value or NULL
void lsm_delete(LSMTree* tree, uint64_t key);
void lsm_free(LSMTree* tree);

#endif
