#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include "btree.h"
#include "lsm.h"

// Simple benchmark timer
double get_time_sec() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

void run_benchmarks() {
    int n = 5000;
    printf("Starting C Benchmarks with N = %d\n", n);

    // --- B-Tree ---
    printf("\n=== B-Tree Benchmark ===\n");
    BTree* btree = btree_create(64);

    // Insert
    double start = get_time_sec();
    for (int i = 0; i < n; i++) {
        btree_insert(btree, i, i);
    }
    double end = get_time_sec();
    printf("B-Tree Insert: %.4f s (%.2f ops/sec)\n", end - start, n / (end - start));

    // Search
    start = get_time_sec();
    for (int i = 0; i < n; i++) {
        btree_search(btree, i); // Simplification: sequential search
    }
    end = get_time_sec();
    printf("B-Tree Search: %.4f s (%.2f ops/sec)\n", end - start, n / (end - start));

    // Delete
    start = get_time_sec();
    for (int i = 0; i < n / 10; i++) { // Delete 10%
        btree_delete(btree, i);
    }
    end = get_time_sec();
    printf("B-Tree Delete: %.4f s (%.2f ops/sec)\n", end - start, (n/10) / (end - start));

    btree_free(btree);


    // --- LSM-Tree ---
    printf("\n=== LSM-Tree Benchmark ===\n");
    // Ensure data dir exists or is handled
    system("rm -rf lsm_data_c");
    system("mkdir -p lsm_data_c");
    
    LSMTree* lsm = lsm_create(1000, "lsm_data_c");

    // Insert
    start = get_time_sec();
    for (int i = 0; i < n; i++) {
        lsm_insert(lsm, i, i);
    }
    end = get_time_sec();
    printf("LSM-Tree Insert: %.4f s (%.2f ops/sec)\n", end - start, n / (end - start));

    // Search
    start = get_time_sec();
    for (int i = 0; i < n; i++) {
        lsm_search(lsm, i);
    }
    end = get_time_sec();
    printf("LSM-Tree Search: %.4f s (%.2f ops/sec)\n", end - start, n / (end - start));

    // LSM Delete (Tombstone)
    start = get_time_sec();
    for (int i = 0; i < n / 10; i++) {
        lsm_delete(lsm, i);
    }
    end = get_time_sec();
    printf("LSM-Tree Delete: %.4f s (%.2f ops/sec)\n", end - start, (n/10) / (end - start));

    lsm_free(lsm);
}

int main() {
    run_benchmarks();
    return 0;
}
