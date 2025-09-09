To run code
gleam deps download
gleam build
gleam run -m main # running program for lukas 1,000,000 4
gleam run -m quick_test #  running program to check lukas 10,000,000 4 with different chunk sizes.
gleam run -m largest_problem # running the largest program solved
time gleam run -m main #to find CPU and Real time ratio
After extensive testing with multiple chunk sizes, we determined that chunk size 10,000 provides the best overall performance for our implementation for very large numbers. For N = 1M and K = 4 we found that chunk size 600 gave the best results The testing was conducted using the quick_test.gleam module, which benchmarks different chunk sizes and measures both wall clock time and CPU utilization.

Testing methodology:

Tested chunk sizes: 1, 10, 100,200,500, 600,700,800,900,1,000, 5,000, 10,000, 25,000, 50,000, 75,000, 100,000, 150,000, and 200,000
Each test measured wall clock time, CPU time, and CPU/Wall ratio
Multiple runs were performed to ensure consistent results
Key findings:

Chunk size 10,000: Optimal performance with best wall clock time for Large N and K
Chunk sizes 25,000, 50,000, and 75,000: Delivered almost similar performance to the optimal size
Larger chunk sizes (100,000+): Showed diminishing returns and slightly worse performance
The result of running your program for lukas 1000000 4: No Output

=== Performance Metrics === Wall clock time (total execution): 1.526 s CPU runtime (process time): 4.59 s CPU time / Real time: 3

The ratio of CPU TIME to REAL TIME: 3

The largest problem solved - lukas 100,000,000 24

Wall clock time (total execution): 7.764 s CPU runtime (process time): 50.29 s CPU time / Real time: 6.47

The ratio of CPU TIME to REAL TIME: 6.47
