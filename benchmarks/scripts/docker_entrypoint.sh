#!/bin/bash

# Wait for Postgres to be ready (double check, though docker-compose healthcheck handles most of it)
echo "Waiting for PostgreSQL..."
until PGPASSWORD=ycsb psql -h "$PG_HOST" -U "ycsb" -d "ycsb" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up - executing setup..."

# Setup Database Schema
PGPASSWORD=ycsb psql -h "$PG_HOST" -U "ycsb" -d "ycsb" -f scripts/setup_db.sql

# If command arguments are provided, execute them
if [ "$#" -gt 0 ]; then
    exec "$@"
fi

# Run Benchmarks
echo "Starting Benchmarks..."

# Update run_all.sh to use the correct host for Postgres
# We can pass the properties directly here or modify the script.
# Let's modify the call in run_all.sh or override it.
# Actually, run_all.sh uses localhost. We need to change it to $PG_HOST.

# Let's create a specific run command here or make run_all.sh smart.
# For now, I will patch run_all.sh in the container or just run the logic here.

# Base directory for all runs
BASE_RUNS_DIR="runs"
mkdir -p $BASE_RUNS_DIR

# Logic to calculate the next run ID
LAST_RUN=$(ls -d $BASE_RUNS_DIR/run_* 2>/dev/null | sort | tail -n 1)
if [ -z "$LAST_RUN" ]; then
    NEXT_NUM=1
else
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

YCSB_DIR="./YCSB"

# Function to run workloads
run_workloads() {
    DB=$1
    DB_PROPS=$2
    OUTPUT_SUBDIR=$3

    echo "Starting benchmarks for $DB..."
    CURRENT_OUTPUT_DIR="$RUN_DIR/results/$OUTPUT_SUBDIR"
    mkdir -p "$CURRENT_OUTPUT_DIR"

    for workload in configs/workload_*; do
        workload_name=$(basename "$workload")
        ADDITIONAL_ARGS=""
        if [ "$workload_name" != "workload_a" ]; then
            ADDITIONAL_ARGS="--skip-load"
        fi

        echo "Running $workload_name on $DB..."
        
        python3 scripts/run_benchmark.py \
            --ycsb-dir "$YCSB_DIR" \
            --db "$DB" \
            --workload "$workload" \
            --output-dir "$CURRENT_OUTPUT_DIR" \
            --db-props "$DB_PROPS" \
            $ADDITIONAL_ARGS
            
        echo "Finished $workload_name on $DB"
    done
}

# 1. Run PostgreSQL Benchmarks
PG_PROPS="-p db.driver=org.postgresql.Driver -p db.url=jdbc:postgresql://$PG_HOST:$PG_PORT/ycsb -p jdbc.url=jdbc:postgresql://$PG_HOST:$PG_PORT/ycsb -p db.user=ycsb -p db.password=ycsb -p db.passwd=ycsb -p jdbc.user=ycsb -p jdbc.password=ycsb"
run_workloads "jdbc" "$PG_PROPS" "postgresql"

# 2. Run RocksDB Benchmarks
ROCKS_DB_DIR="/tmp/rocksdb_data"
mkdir -p $ROCKS_DB_DIR
rm -rf "$ROCKS_DB_DIR"/*
ROCKS_PROPS="-p rocksdb.dir=$ROCKS_DB_DIR"
run_workloads "rocksdb" "$ROCKS_PROPS" "rocksdb"

echo "Benchmarks Completed."

# 3. Run Analysis
echo "Generating Analysis..."
python3 analysis/analyze_results.py "$RUN_DIR"

echo "Done! Full records (results and charts) are in: $RUN_DIR"
