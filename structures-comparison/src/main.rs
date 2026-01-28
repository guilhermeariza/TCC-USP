mod btree;
mod lsm;
mod bench;

fn main() {
    println!("Running Structures Comparison Benchmark...");
    bench::run_benchmarks();
}
