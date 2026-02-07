# B-Tree vs LSM-Tree: C Implementation (NVMe Optimized)

This project contains a highly optimized C implementation of **B-Tree** and **LSM-Tree** data structures, designed to benchmark their performance on modern **NVMe SSDs** using **Direct I/O**.

This code serves as a "Micro-Benchmark" proof-of-concept for the TCC: *"Comparative Performance Analysis between B-Trees and LSM-Trees on Modern Hardware"*.

## TCC Alignment & Key Features

This implementation is aligned with specific hypotheses from the research project:

1.  **NVMe Direct I/O (`O_DIRECT`)**:
    - Bypasses OS Page Cache (RAM) to measure *real* disk latency and bandwidth.
    - Simulates the behavior of database engines (like Postgres/RocksDB) doing persistence.
2.  **Multithreading (Queue Depth)**:
    - Uses 8 worker threads to stress the NVMe native parallelism (Queue Depth).
3.  **Write Amplification Factor (WAF)** (Hipótese 3):
    - Instruments **Logical Bytes** (Application payload) vs **Physical Bytes** (Actual disk I/O).
    - Demonstrates why B-Trees wear out SSDs faster than LSM-Trees.
4.  **Mixed Workloads (Workload A)**:
    - Simulates YCSB Workload A (50% Read / 50% Update) to test concurrent performance.

## Project Structure

*   `src/btree.c`: In-memory B-Tree with `O_DIRECT` dirty page simulation on Insert.
*   `src/lsm.c`: Log-Structured Merge Tree with in-memory MemTable + `O_DIRECT` SSTable flushing.
*   `src/main.c`: Benchmark runner (throughput, latency, WAF).
*   `Dockerfile`: Alpine Linux environment with `gcc` and `musl` for static compilation.

## How to Run

### Option 1: Docker (Recommended)
This approach guarantees dependencies (Linux headers for `O_DIRECT`, `pthread`) work on any OS (including Windows).

```bash
# Build the image
docker build -t structures-benchmark-c .

# Run the benchmark
docker run --rm structures-benchmark-c
```

### Option 2: Linux/WSL Manual Build
Requires `gcc` and `make`.

```bash
cd structures-comparison-c
gcc -O3 -pthread -o benchmark src/main.c src/btree.c src/lsm.c
./benchmark
```

## Expected Results (On NVMe)

You should observe results similar to:

-   **B-Tree**: High WAF (~256) and lower throughput due to random 4KB writes.
-   **LSM-Tree**: Low WAF (<1.0) and high throughput due to sequential batching.

## License
Academic/MIT.
