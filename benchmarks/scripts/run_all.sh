#!/bin/bash

# Directory for results
RESULTS_DIR="results"
mkdir -p $RESULTS_DIR

# YCSB Directory (created by build_ycsb.sh)
YCSB_DIR="./YCSB"

# Check if YCSB exists
if [ ! -d "$YCSB_DIR" ]; then
    echo "Error: YCSB directory not found at $YCSB_DIR"
    echo "Please clone and build YCSB first (see walkthrough.md)"
    exit 1
fi

# Function to run workloads
run_workloads() {
    DB=$1
    DB_PROPS=$2
    OUTPUT_SUBDIR=$3

    echo "Starting benchmarks for $DB..."
    mkdir -p "$RESULTS_DIR/$OUTPUT_SUBDIR"

    for workload in configs/workload_*; do
        workload_name=$(basename "$workload")
        echo "Running $workload_name on $DB..."
        
        python3 scripts/run_benchmark.py \
            --ycsb-dir "$YCSB_DIR" \
            --db "$DB" \
            --workload "$workload" \
            --output-dir "$RESULTS_DIR/$OUTPUT_SUBDIR" \
            --db-props "$DB_PROPS"
            
        echo "Finished $workload_name on $DB"
        echo "------------------------------------------------"
    done
}

# Run PostgreSQL Benchmarks
# Assumes Postgres is running and setup_db.sql has been executed
PG_PROPS="-p jdbc.url=jdbc:postgresql://localhost:5432/ycsb -p jdbc.user=ycsb -p jdbc.password=ycsb"
run_workloads "postgresql" "$PG_PROPS" "postgresql"

# Run RocksDB Benchmarks
ROCKS_DB_DIR="/tmp/rocksdb_data"
mkdir -p $ROCKS_DB_DIR
ROCKS_PROPS="-p rocksdb.dir=$ROCKS_DB_DIR"
run_workloads "rocksdb" "$ROCKS_PROPS" "rocksdb"

echo "All benchmarks completed!"
echo "To analyze results, run: python3 analysis/analyze_results.py $RESULTS_DIR"
