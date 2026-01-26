#!/bin/bash

# Update package list
sudo apt-get update

# Install Java (required for YCSB)
sudo apt-get install -y openjdk-11-jdk

# Install Maven (for building YCSB)
sudo apt-get install -y maven

# Install Python 3
sudo apt-get install -y python3 python3-pip

# Install Build Essentials (for compiling RocksDB/YCSB bindings)
sudo apt-get install -y build-essential

# Install PostgreSQL (for B-Tree tests)
sudo apt-get install -y postgresql postgresql-contrib

# Install system monitoring tools
sudo apt-get install -y dstat sysstat

echo "Dependencies installed successfully."
