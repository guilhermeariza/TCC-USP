#!/bin/bash

# run_docker_benchmarks.sh
# Wrapper script to run YCSB benchmarks with a guaranteed clean state.

echo "================================================================"
echo "      Starting Benchmark Suite (Clean Slate Strategy)           "
echo "================================================================"

echo "[1/3] Cleaning up previous benchmark state..."
# -v: Remove named volumes declared in the `volumes` section of the Compose file.
# --remove-orphans: Remove containers for services not defined in the Compose file.
docker-compose down -v --remove-orphans

if [ $? -ne 0 ]; then
    echo "Error: Failed to clean up Docker environment."
    exit 1
fi

echo "[2/3] Building and Starting Containers..."
# --build: Build images before starting containers.
# --abort-on-container-exit: Stops all containers if any container was stopped.
# --exit-code-from benchmark: Return the exit code of the selected service container.
docker-compose up --build --abort-on-container-exit --exit-code-from benchmark

EXIT_CODE=$?

echo "================================================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "      Benchmarks Completed Successfully                         "
else
    echo "      Benchmarks Failed (Exit Code: $EXIT_CODE)                 "
fi
echo "================================================================"

exit $EXIT_CODE
