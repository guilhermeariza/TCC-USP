use crate::btree::BTree;
use crate::lsm::LSMTree;
use std::time::Instant;
use rand::Rng;
use std::fs;

pub trait StorageEngine {
    fn insert(&mut self, key: u64, value: u64);
    fn search(&self, key: &u64) -> Option<u64>;
    fn delete(&mut self, key: u64);
    fn name(&self) -> &str;
    fn cleanup(&mut self) {} // Optional cleanup for LSM
}

impl StorageEngine for BTree<u64, u64> {
    fn insert(&mut self, key: u64, value: u64) {
        self.insert(key, value);
    }

    fn search(&self, key: &u64) -> Option<u64> {
        self.search(key).cloned()
    }

    fn delete(&mut self, key: u64) {
        self.delete(key);
    }
    
    fn name(&self) -> &str {
        "B-Tree"
    }
}

impl StorageEngine for LSMTree<u64, u64> {
    fn insert(&mut self, key: u64, value: u64) {
        self.insert(key, value);
    }

    fn search(&self, key: &u64) -> Option<u64> {
        self.search(key)
    }

    fn delete(&mut self, key: u64) {
        self.delete(key);
    }
    
    fn name(&self) -> &str {
        "LSM-Tree"
    }
    
    fn cleanup(&mut self) {
        // LSM specific cleanup (compaction or deleting dir) if needed between runs
        // But here we usually want persistence. For benchmark we might reset.
        // We implemented 'compact' but not 'clear'.
    }
}

pub fn run_benchmarks() {
    let n = 100_000; // Benchmark size
    println!("Starting benchmarks with N = {}", n);

    // 1. Setup B-Tree
    let mut btree = BTree::new(64); // Degree 64

    // 2. Setup LSM-Tree
    // Use a temp dir or specific dir
    let lsm_dir = "lsm_data_bench";
    if std::path::Path::new(lsm_dir).exists() {
        fs::remove_dir_all(lsm_dir).unwrap();
    }
    let mut lsm = LSMTree::new(1000, lsm_dir); // Threshold 1000

    println!("\n=== B-Tree Benchmark ===");
    run_engine_benchmark(&mut btree, n);

    println!("\n=== LSM-Tree Benchmark ===");
    run_engine_benchmark(&mut lsm, n);
    
    // Cleanup
    if std::path::Path::new(lsm_dir).exists() {
        fs::remove_dir_all(lsm_dir).expect("Failed to clean up LSM data");
    }
}

fn run_engine_benchmark(engine: &mut impl StorageEngine, n: u64) {
    let mut rng = rand::thread_rng();
    
    // Gen Data
    let mut keys: Vec<u64> = (0..n).map(|_| rng.gen_range(0..n*10)).collect();
    
    // --- INSERT ---
    let start = Instant::now();
    for &k in &keys {
        engine.insert(k, k); // Value = Key
    }
    let duration = start.elapsed();
    println!("{}: Insert {} items took {:.2?}", engine.name(), n, duration);
    println!("Throughput: {:.2} ops/sec", n as f64 / duration.as_secs_f64());

    // --- READ (Random) ---
    // Shuffle or random sample
    let search_ops = n / 2;
    let start = Instant::now();
    for _ in 0..search_ops {
        let k = keys[rng.gen_range(0..keys.len())];
        engine.search(&k);
    }
    let duration = start.elapsed();
    println!("{}: Read {} items took {:.2?}", engine.name(), search_ops, duration);
    println!("Throughput: {:.2} ops/sec", search_ops as f64 / duration.as_secs_f64());
    
    // --- UPDATE ---
    let update_ops = n / 10;
    let start = Instant::now();
    for _ in 0..update_ops {
        let k = keys[rng.gen_range(0..keys.len())];
        engine.insert(k, k + 1);
    }
    let duration = start.elapsed();
    println!("{}: Update {} items took {:.2?}", engine.name(), update_ops, duration);
    println!("Throughput: {:.2} ops/sec", update_ops as f64 / duration.as_secs_f64());

    // --- DELETE ---
    let delete_ops = n / 10;
    let start = Instant::now();
    for _ in 0..delete_ops {
        let idx = rng.gen_range(0..keys.len());
        let k = keys[idx];
        engine.delete(k);
    }
    let duration = start.elapsed();
    println!("{}: Delete {} items took {:.2?}", engine.name(), delete_ops, duration);
    println!("Throughput: {:.2} ops/sec", delete_ops as f64 / duration.as_secs_f64());
}
