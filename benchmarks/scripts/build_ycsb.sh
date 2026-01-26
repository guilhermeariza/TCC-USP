#!/bin/bash

# Go to benchmarks root
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# Clone YCSB if it doesn't exist
if [ ! -d "YCSB" ]; then
    echo "Cloning YCSB repository..."
    git clone https://github.com/brianfrankcooper/YCSB.git
else
    echo "YCSB repository already exists."
fi

cd YCSB

# Build with RocksDB binding
echo "Building YCSB with RocksDB support..."
mvn -pl site.ycsb:rocksdb-binding -am clean package -DskipTests

if [ $? -eq 0 ]; then
    echo "YCSB built successfully!"
else
    echo "YCSB build failed. Please check the errors above."
    exit 1
fi

cd "$PROJECT_ROOT"
