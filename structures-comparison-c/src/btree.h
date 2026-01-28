#ifndef BTREE_H
#define BTREE_H

#include <stdint.h>
#include <stdbool.h>

typedef struct BTreeNode BTreeNode;

struct BTreeNode {
    uint64_t *keys;
    uint64_t *values;
    struct BTreeNode **children;
    int num_keys;
    int t; // Minimum degree
    bool is_leaf;
};

typedef struct {
    BTreeNode *root;
    int t; // Min degree
} BTree;

BTree* btree_create(int t);
void btree_insert(BTree *tree, uint64_t key, uint64_t value);
uint64_t* btree_search(BTree *tree, uint64_t key);
void btree_delete(BTree *tree, uint64_t key);
void btree_free(BTree *tree);

#endif
