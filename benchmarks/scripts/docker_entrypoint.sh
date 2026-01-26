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

# Run Benchmarks
echo "Starting Benchmarks..."

# Update run_all.sh to use the correct host for Postgres
# We can pass the properties directly here or modify the script.
# Let's modify the call in run_all.sh or override it.
# Actually, run_all.sh uses localhost. We need to change it to $PG_HOST.

# Let's create a specific run command here or make run_all.sh smart.
# For now, I will patch run_all.sh in the container or just run the logic here.

# Define directories
RESULTS_DIR="results"
mkdir -p $RESULTS_DIR
YCSB_DIR="./YCSB"

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
    done
}

# 1. Run PostgreSQL Benchmarks
PG_PROPS="-p db.driver=org.postgresql.Driver -p db.url=jdbc:postgresql://$PG_HOST:$PG_PORT/ycsb -p jdbc.url=jdbc:postgresql://$PG_HOST:$PG_PORT/ycsb -p db.user=ycsb -p db.password=ycsb -p db.passwd=ycsb -p jdbc.user=ycsb -p jdbc.password=ycsb"
run_workloads "jdbc" "$PG_PROPS" "postgresql"

# 2. Run RocksDB Benchmarks
# RocksDB is embedded, so it runs locally in the container
ROCKS_DB_DIR="/tmp/rocksdb_data"
mkdir -p $ROCKS_DB_DIR
ROCKS_PROPS="-p rocksdb.dir=$ROCKS_DB_DIR"
run_workloads "rocksdb" "$ROCKS_PROPS" "rocksdb"

echo "Benchmarks Completed."

# 3. Run Analysis
echo "Generating Analysis..."
python3 analysis/analyze_results.py results/

echo "Done! Results are in the 'results' folder and charts in 'analysis/charts'."
