#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <dirent.h>
#include "lsm.h"

// Basic MemTable Node (BST)
typedef struct MemNode {
    uint64_t key;
    uint64_t value;
    int is_tombstone;
    struct MemNode *left, *right;
} MemNode;

struct LSMTree {
    MemNode *memtable_root;
    size_t size;
    size_t threshold;
    char *data_dir;
};

MemNode* mn_create(uint64_t k, uint64_t v, int tomb) {
    MemNode* n = (MemNode*)malloc(sizeof(MemNode));
    n->key = k; n->value = v; n->is_tombstone = tomb;
    n->left = n->right = NULL;
    return n;
}

MemNode* mn_insert(MemNode* root, uint64_t k, uint64_t v, int tomb, size_t *size_counter) {
    if (!root) {
        (*size_counter)++;
        return mn_create(k, v, tomb);
    }
    if (k < root->key) root->left = mn_insert(root->left, k, v, tomb, size_counter);
    else if (k > root->key) root->right = mn_insert(root->right, k, v, tomb, size_counter);
    else {
        root->value = v;
        root->is_tombstone = tomb;
    }
    return root; 
}

void mn_free(MemNode* root) {
    if (!root) return;
    mn_free(root->left);
    mn_free(root->right);
    free(root);
}

// In-order traversal to flush
void mn_flush_rec(MemNode* node, FILE* f) {
    if (!node) return;
    mn_flush_rec(node->left, f);
    fprintf(f, "%lu %lu %d\n", node->key, node->value, node->is_tombstone);
    mn_flush_rec(node->right, f);
}

LSMTree* lsm_create(size_t threshold, const char* data_dir) {
    LSMTree* t = (LSMTree*)malloc(sizeof(LSMTree));
    t->memtable_root = NULL;
    t->size = 0;
    t->threshold = threshold;
    t->data_dir = strdup(data_dir);
    return t;
}

void lsm_flush(LSMTree* t) {
    if (!t->memtable_root) return;
    
    char path[256];
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    snprintf(path, sizeof(path), "%s/sst_%ld_%ld.txt", t->data_dir, ts.tv_sec, ts.tv_nsec);
    
    FILE *f = fopen(path, "w");
    if (f) {
        mn_flush_rec(t->memtable_root, f);
        fclose(f);
    }
    mn_free(t->memtable_root);
    t->memtable_root = NULL;
    t->size = 0;
}

void lsm_insert(LSMTree* t, uint64_t k, uint64_t v) {
    t->memtable_root = mn_insert(t->memtable_root, k, v, 0, &t->size);
    if (t->size >= t->threshold) {
        lsm_flush(t);
    }
}

void lsm_delete(LSMTree* t, uint64_t k) {
    t->memtable_root = mn_insert(t->memtable_root, k, 0, 1, &t->size);
    if (t->size >= t->threshold) {
        lsm_flush(t);
    }
}

uint64_t* lsm_search(LSMTree* t, uint64_t k) {
    // 1. Search MemTable
    MemNode* cur = t->memtable_root;
    while (cur) {
        if (k == cur->key) {
            if (cur->is_tombstone) return NULL;
            return &cur->value; 
        }
        else if (k < cur->key) cur = cur->left;
        else cur = cur->right;
    }
    
    // 2. Search SSTables
    DIR *d;
    struct dirent *dir;
    d = opendir(t->data_dir);
    if (d) {
        while ((dir = readdir(d)) != NULL) {
            if (strstr(dir->d_name, "sst_") != NULL) {
                char path[512];
                snprintf(path, sizeof(path), "%s/%s", t->data_dir, dir->d_name);
                FILE *f = fopen(path, "r");
                if (f) {
                    uint64_t fk, fv;
                    int ftomb;
                    while (fscanf(f, "%lu %lu %d", &fk, &fv, &ftomb) == 3) {
                        if (fk == k) {
                            fclose(f);
                            closedir(d);
                            if (ftomb) return NULL;
                            static uint64_t temp_val;
                            temp_val = fv;
                            return &temp_val;
                        }
                    }
                    fclose(f);
                }
            }
        }
        closedir(d);
    }
    return NULL;
}

void lsm_free(LSMTree* t) {
    mn_free(t->memtable_root);
    if (t->data_dir) free(t->data_dir);
    free(t);
}
