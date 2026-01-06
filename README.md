
# Parallel Gleam Program — Performance Benchmarking

This project implements a **parallel Gleam program** to solve the *Lukas problem* efficiently using **actor-based concurrency** and configurable **chunk sizes**. Extensive benchmarking was performed to analyze scalability, CPU utilization, and wall-clock performance.

---

## How to Run

```bash
# Install dependencies
gleam deps download

# Build the project
gleam build

# Run main program (example: N = 1,000,000, K = 4)
gleam run -m main

# Benchmark different chunk sizes
gleam run -m quick_test

# Run the largest solved configuration
gleam run -m largest_problem
```

---

## Testing Methodology

Benchmarks were executed using the `quick_test.gleam` module.

**Tested chunk sizes:**

```
1, 10, 100, 200, 500, 600, 700, 800, 900,
1,000, 5,000, 10,000, 25,000, 50,000,
75,000, 100,000, 150,000, 200,000
```

For each configuration:

* Measured **wall clock time**
* Measured **CPU runtime**
* Computed **CPU / Wall-time ratio**
* Performed **multiple runs** to ensure consistency

---

## Key Findings

### Optimal Chunk Sizes

* **Chunk size 10,000** delivered the **best overall performance** for very large inputs.
* For **N = 1,000,000 and K = 4**, **chunk size 600** produced the fastest execution.
* Chunk sizes **25,000–75,000** performed nearly as well as the optimal size.
* Chunk sizes **≥100,000** showed diminishing returns and slightly worse performance.

---

## Performance Results

### N = 1,000,000, K = 4

```
Wall clock time:     1.526 s
CPU runtime:         4.59 s
CPU / Real time:    3.00
```

### Largest Problem Solved — N = 100,000,000, K = 24

```
Wall clock time:     7.764 s
CPU runtime:         50.29 s
CPU / Real time:    6.47
```

A CPU/real-time ratio greater than 1 confirms **effective parallel execution** across multiple cores.

---

## Summary

* Demonstrates **scalable parallel computation** using Gleam actors
* Empirically determines **optimal chunk sizes** for different workloads
* Achieves strong CPU utilization and near-linear scaling on large inputs
* Successfully solves inputs up to **N = 100 million**
