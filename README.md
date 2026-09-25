# Task — Sequential Baseline: Linear Regression via Normal Equations

## Context

Given a dataset of `N` observations, each described by `p` predictor variables, linear regression seeks the coefficient vector `β` (size `p`) that best fits the data in a least-squares sense:

```
minimize  ||Xβ - y||²
```

where `X` is the `N × p` matrix of observations and `y` is the `N × 1` vector of target values. This problem has a closed-form solution obtained by setting the gradient to zero, which leads to the **normal equations**:

```
(XᵀX) β = Xᵀy
```

`XᵀX` is a `p × p` symmetric positive-definite matrix, and `Xᵀy` is a `p × 1` vector. Solving for `β` therefore requires two steps:

1. **Matrix multiplication**: compute `XᵀX` (and `Xᵀy`).
2. **Linear system solve**: solve the resulting `p × p` system for `β`.

## Task

Implement a **sequential, non-optimized** baseline version of this linear regression pipeline: naive (ijk) matrix multiplication for `XᵀX`/`Xᵀy`, followed by Gaussian elimination (with partial pivoting) and back substitution to solve the resulting system. No blocking, vectorization, or parallelization: clarity and correctness first. This baseline is your reference for later optimization stages.

Add (and try) an alternative solver for the linear equation system, using Gauss-Jordan instead of simple Gaussian elimination. Modify the code to allow the switching between both (non-optimizes so far) solvers.

You are given a routine that generates synthetic data: a random `X`, a known ground-truth `β_true`, and `y = X·β_true + noise`. This lets you verify your computed `β` against the known ground truth.

## Configurations to Test

You must run and report results for the following three `(N, p)` configurations, chosen to stress the two kernels differently:

| Config | N (observations) | p (variables) | What it illustrates |
|---|---|---|---|
| 1 | 20,000 | 50 | Matmul-dominated; the resulting system is tiny and cheap to solve |
| 2 | 50,000 | 300 | Matmul-dominated, but `X` itself is now too large to fit in cache |
| 3 | 2,000 | 2,000 | Matmul and system-solve costs become comparable — both kernels matter |

## Deliverables

1. Source code implementing the baseline.
2. A short benchmarking report in FT3, including: verification that your `β` matches `β_true` within tolerance, and execution time for each configuration above (averaged over multiple runs, as usual).
  - The benchmarking will show results with binaries built with `gcc-10.1.0`, `icc 2021.3.0` and `icx 2021.3.0` using these optimization levels: `-O0`, `-O2`, `-O3` and `-Ofast` (include -march=native in every level greater than `O0`).
  - Consider the total execution time for the linear regression computation, after allocating and generating the data structures.

## Reproducing the submitted experiments

The submitted implementation is intended to run on an FT3 compute node.

### Fresh-clone setup

Slurm creates its output file before the batch script starts. Create the output
directories once after cloning:

```bash
mkdir -p logs bin results
make --version
```

This repository requires GNU Make 3.82 or newer because the `Makefile` uses
`.RECIPEPREFIX`. FT3 provides a compatible GNU Make.

### Formal benchmark runs

The scripts rebuild every binary on the allocated compute node. This is
important because the optimized builds use `-march=native`.

```bash
sbatch benchmark.slurm gaussian 3
sbatch benchmark.slurm gauss-jordan 3
```

After both jobs complete, combine the raw measurements and regenerate the
report:

```bash
bash summarize_results.sh \
  results/benchmark-gaussian-GAUSSIAN_JOBID.csv \
  results/benchmark-gauss-jordan-GAUSS_JORDAN_JOBID.csv

bash generate_report.sh
```

`logs/` and `bin/` are intentionally ignored. The final raw CSV files,
environment records, summary CSV, and `REPORT.md` are version controlled.
