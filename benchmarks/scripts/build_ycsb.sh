#!/bin/bash
set -e

# Go to benchmarks root
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# Clone YCSB source if it doesn't exist
if [ ! -d "YCSB-src" ]; then
    echo "Cloning YCSB repository..."
    git clone https://github.com/brianfrankcooper/YCSB.git YCSB-src
else
    echo "YCSB source repository already exists."
fi

cd YCSB-src

# Build with RocksDB and JDBC bindings
echo "Building YCSB with RocksDB and JDBC support..."
mvn -pl site.ycsb:rocksdb-binding,site.ycsb:jdbc-binding -am clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "YCSB build failed. Please check the errors above."
    exit 1
fi

echo "YCSB compilation successful!"

# Extract the release tarballs
cd "$PROJECT_ROOT"
echo "Extracting YCSB release packages..."

# Remove old YCSB directory if it exists
rm -rf YCSB

# Extract the RocksDB tarball (this will be our base)
tar -xzf YCSB-src/rocksdb/target/ycsb-rocksdb-binding-0.18.0-SNAPSHOT.tar.gz

# Rename to YCSB
mv ycsb-rocksdb-binding-0.18.0-SNAPSHOT YCSB

# Extract JDBC binding and copy its libraries
echo "Adding JDBC binding..."
tar -xzf YCSB-src/jdbc/target/ycsb-jdbc-binding-0.18.0-SNAPSHOT.tar.gz
cp -r ycsb-jdbc-binding-0.18.0-SNAPSHOT/lib/* YCSB/lib/
rm -rf ycsb-jdbc-binding-0.18.0-SNAPSHOT

echo "YCSB built and extracted successfully!"
echo "YCSB binary is ready at: $PROJECT_ROOT/YCSB/bin/ycsb"
echo "Bindings available: jdbc, rocksdb"
