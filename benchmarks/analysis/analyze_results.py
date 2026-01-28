import os
import pandas as pd
import matplotlib.pyplot as plt
import re
import sys

def parse_ycsb_log(file_path):
    metrics = {}
    with open(file_path, 'r') as f:
        for line in f:
            if "[OVERALL], Throughput(ops/sec)" in line:
                metrics['Throughput'] = float(line.split(',')[-1].strip())
            if "[UPDATE], AverageLatency(us)" in line:
                metrics['Update_Avg_Lat'] = float(line.split(',')[-1].strip())
            if "[READ], AverageLatency(us)" in line:
                metrics['Read_Avg_Lat'] = float(line.split(',')[-1].strip())
            # Add more parsing as needed for P95, P99 etc.
            if "[UPDATE], 95thPercentileLatency(us)" in line:
                metrics['Update_P95_Lat'] = float(line.split(',')[-1].strip())
            if "[READ], 95thPercentileLatency(us)" in line:
                metrics['Read_P95_Lat'] = float(line.split(',')[-1].strip())
                
    return metrics

def main():
    results_dir = sys.argv[1] if len(sys.argv) > 1 else "results"
    data = []

    for root, dirs, files in os.walk(results_dir):
        for filename in files:
            if filename.endswith(".log") and "run" in filename:
                # Expected filename format: {db}_{workload}_run_{timestamp}.log
                parts = filename.split('_')
                if len(parts) >= 3:
                    db = parts[0]
                    workload = parts[1] + "_" + parts[2] # e.g. workload_a
                    
                    filepath = os.path.join(root, filename)
                    metrics = parse_ycsb_log(filepath)
                    
                    row = {'DB': db, 'Workload': workload}
                    row.update(metrics)
                    data.append(row)

    df = pd.DataFrame(data)
    
    if df.empty:
        print("No data found to analyze.")
        return

    print("Aggregated Results:")
    print(df)

    # Generate Charts
    charts_dir = os.path.join(results_dir, "analysis", "charts")
    os.makedirs(charts_dir, exist_ok=True)
    
    # Throughput Comparison
    # Filter out 0 throughput (failed runs)
    df = df[df['Throughput'] > 0]
    
    if df.empty:
        print("No valid data found (Throughput > 0).")
        return

    # Use pivot_table to handle duplicates (taking the max throughput found)
    pivot_throughput = df.pivot_table(index='Workload', columns='DB', values='Throughput', aggfunc='max')
    pivot_throughput.plot(kind='bar', figsize=(10, 6))
    plt.title('Throughput Comparison (Ops/sec)')
    plt.ylabel('Throughput (ops/sec)')
    plt.tight_layout()
    throughput_path = os.path.join(charts_dir, 'throughput_comparison.png')
    plt.savefig(throughput_path)
    print(f"Generated {throughput_path}")

    # Latency Comparison (Read Avg)
    if 'Read_Avg_Lat' in df.columns:
        pivot_latency = df.pivot_table(index='Workload', columns='DB', values='Read_Avg_Lat', aggfunc='mean')
        pivot_latency.plot(kind='bar', figsize=(10, 6))
        plt.title('Read Average Latency Comparison')
        plt.ylabel('Latency (us)')
        plt.tight_layout()
        latency_path = os.path.join(charts_dir, 'read_latency_comparison.png')
        plt.savefig(latency_path)
        print(f"Generated {latency_path}")

if __name__ == "__main__":
    main()
