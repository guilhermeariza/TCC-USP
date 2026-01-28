# Structures Comparison (C Implementation)

This project implements B-Tree and LSM-Tree in pure C and benchmarks them.

## Structure
- `src/btree.c`: B-Tree implementation (In-memory)
- `src/lsm.c`: LSM-Tree implementation (MemTable + SSTable flush)
- `src/main.c`: Benchmark runner

## Running with Docker (Recommended)
This ensures a consistent Linux environment (Ubuntu).

1. Build the image:
   ```bash
   docker build -t structures-benchmark-c .
   ```

2. Run:
   ```bash
   docker run --rm structures-benchmark-c
   ```

## Running Locally (if GCC available)
```bash
make
./benchmark
```
