import argparse
import subprocess
import time
import os
import datetime

def run_command(command, cwd=None, output_file=None):
    print(f"Executing: {command}")
    process = subprocess.Popen(command, shell=True, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout, _ = process.communicate()

    # Save output to file if specified
    if output_file:
        output_dir = os.path.dirname(output_file)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        with open(output_file, 'wb') as f:
            f.write(stdout)

    if process.returncode != 0:
        print(f"Error executing command: {command}")
        if not output_file:
            print(stdout.decode())
        return False
    return stdout.decode()

def run_ycsb(ycsb_dir, db_binding, workload, operation, threads, props, output_file):
    ycsb_bin = os.path.join(ycsb_dir, "bin", "ycsb")
    if not os.path.exists(ycsb_bin):
        print(f"Error: YCSB binary not found at {ycsb_bin}. Please build YCSB first.")
        return False

    # Use absolute paths to avoid issues with cwd
    ycsb_abs = os.path.abspath(ycsb_bin)
    workload_abs = os.path.abspath(workload)

    cmd = f"{ycsb_abs} {operation} {db_binding} -s -P {workload_abs} -p threadcount={threads} {props}"
    return run_command(cmd, cwd=None, output_file=output_file)

def main():
    parser = argparse.ArgumentParser(description='Run YCSB Benchmark')
    parser.add_argument('--ycsb-dir', required=True, help='Path to YCSB directory')
    parser.add_argument('--db', required=True, choices=['postgresql', 'rocksdb'], help='Database binding to use')
    parser.add_argument('--workload', required=True, help='Path to workload config file')
    parser.add_argument('--threads', type=int, default=1, help='Number of threads')
    parser.add_argument('--output-dir', required=True, help='Directory to save results')
    parser.add_argument('--db-props', default='', help='Additional DB properties (e.g., "-p rocksdb.dir=/tmp/rocksdb")')

    args = parser.parse_args()

    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    workload_name = os.path.basename(args.workload)
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)

    # Load Phase
    print(f"Starting LOAD phase for {args.db} with {workload_name}...")
    load_output = os.path.join(args.output_dir, f"{args.db}_{workload_name}_load_{timestamp}.log")
    run_ycsb(args.ycsb_dir, args.db, args.workload, 'load', args.threads, args.db_props, load_output)
    
    # Run Phase
    print(f"Starting RUN phase for {args.db} with {workload_name}...")
    run_output = os.path.join(args.output_dir, f"{args.db}_{workload_name}_run_{timestamp}.log")
    
    # Start system monitoring (simple example using dstat if available, or just timestamp)
    start_time = time.time()
    
    run_ycsb(args.ycsb_dir, args.db, args.workload, 'run', args.threads, args.db_props, run_output)
    
    end_time = time.time()
    duration = end_time - start_time
    print(f"Benchmark completed in {duration:.2f} seconds.")
    print(f"Results saved to {args.output_dir}")

if __name__ == "__main__":
    main()
