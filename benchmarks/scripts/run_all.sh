#!/bin/bash

# Base directory for all runs
BASE_RUNS_DIR="runs"
mkdir -p $BASE_RUNS_DIR

# Logic to calculate the next run ID
LAST_RUN=$(ls -d $BASE_RUNS_DIR/run_* 2>/dev/null | sort | tail -n 1)
if [ -z "$LAST_RUN" ]; then
    NEXT_NUM=1
else
    # Extract number from format run_001_...
    LAST_NUM=$(basename "$LAST_RUN" | cut -d'_' -f2 | sed 's/^0*//')
    NEXT_NUM=$((LAST_NUM + 1))
fi

# Format with leading zeros and timestamp
RUN_ID=$(printf "run_%03d_%s" $NEXT_NUM "$(date +%Y%m%d_%H%M%S)")
RUN_DIR="$BASE_RUNS_DIR/$RUN_ID"
mkdir -p "$RUN_DIR"

echo "================================================================"
echo "Starting Benchmark Run: $RUN_ID"
echo "Results will be saved to: $RUN_DIR"
echo "================================================================"

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
    # Results are now nested under the specific RUN_DIR
    CURRENT_OUTPUT_DIR="$RUN_DIR/results/$OUTPUT_SUBDIR"
    mkdir -p "$CURRENT_OUTPUT_DIR"

    for workload in configs/workload_*; do
        workload_name=$(basename "$workload")
        echo "Running $workload_name on $DB..."
        
        python3 scripts/run_benchmark.py \
            --ycsb-dir "$YCSB_DIR" \
            --db "$DB" \
            --workload "$workload" \
            --output-dir "$CURRENT_OUTPUT_DIR" \
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
# Cleanup previous RocksDB data to ensure a fresh run
rm -rf "$ROCKS_DB_DIR"/*
ROCKS_PROPS="-p rocksdb.dir=$ROCKS_DB_DIR"
run_workloads "rocksdb" "$ROCKS_PROPS" "rocksdb"

echo "All benchmarks completed!"

# Run Analysis
echo "Generating Analysis..."
# Analysis script now handles charts creation inside the RUN_DIR
python3 analysis/analyze_results.py "$RUN_DIR"

echo "Done! Full records (results and charts) are in: $RUN_DIR"
