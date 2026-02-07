# B-Tree vs LSM-Tree: Rust Implementation

This is the **Rust** implementation of the data structures benchmark for the TCC Project.

While the C implementation (`../structures-comparison-c`) focuses on raw NVMe simulation (`O_DIRECT`, pointers, manual memory), this Rust version focuses on **Safety, Correctness, and Modern Concurrency**.

## Project Goals

1.  **Safety**: Implement complex disk structures (B-Tree, LSM) without memory leaks or segfaults, leveraging Rust's ownership model.
2.  **Concurrency**: Utilize Rust's `std::sync` (Mutex/Arc) or channels for safe parallel workload execution.
3.  **Cross-Platform**: Run seamlessly on Windows, Linux, and macOS without the strict POSIX dependencies of the C version.

## Structure

*   `src/btree.rs`: B-Tree implementation.
*   `src/lsm.rs`: LSM-Tree implementation (MemTable + SSTable).
*   `src/bench.rs`: Benchmark logic.
*   `src/main.rs`: Entry point.

## How to Run

Ensure you have Rust installed (`rustup`).

```bash
cd structures-comparison

# Run benchmarks in release mode (Essential for performance)
cargo run --release
```

## Comparison with C Version

| Feature | Rust Version | C Version |
| :--- | :--- | :--- |
| **Focus** | Safety & Logic Verification | NVMe HW Simulation (O_DIRECT) |
| **I/O** | Standard Buffered I/O | Direct I/O (Bypass Cache) |
| **OS Support** | Universal | Linux/Docker (Simulated) |
