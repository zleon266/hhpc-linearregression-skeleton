#!/bin/bash
# Generate the English benchmarking report for the HHPC Block 1
# sequential-linear-regression assignment.

set -euo pipefail

summary="${1:-results/benchmark-summary.csv}"
report="${2:-REPORT.md}"

if [ ! -f "$summary" ]; then
    echo "Missing summary file: $summary" >&2
    exit 1
fi

{
    cat <<'EOF'
# HHPC Block 1 — Sequential Linear Regression Baseline

## Implementation

This repository implements sequential linear regression through the normal
equations:

```text
(X^T X) beta = X^T y
```

The baseline computes `X^T X` with a naive triple loop and `X^T y` with a
naive double loop. It then solves the linear system with either:

- Gaussian elimination with partial pivoting and back substitution.
- Gauss-Jordan elimination with partial pivoting.

No blocking, explicit vectorization, or parallelization is used in the
implementation.

## Experimental method

Experiments were run on a FinisTerrae III (FT3) compute node (`c205-10`), not
on a login node. Each program was run with one CPU core and was rebuilt on the
allocated compute node before measurement.

- Compilers: GCC 10.1.0, ICC 2021.3.0, and ICX 2021.3.0.
- Optimization levels: `-O0`, `-O2`, `-O3`, and `-Ofast`.
- `-march=native` was included for every level above `-O0`.
- Three repetitions were used for every compiler, optimization level, solver,
  and configuration.
- Synthetic data used seed `42` and `noise_std=0.0`.
- Reported timings begin after allocation and synthetic-data generation, and
  include `X^T X`, `X^T y`, and the linear-system solve.

The measured configurations were:

| Configuration | N | p |
|---|---:|---:|
| 1 | 20,000 | 50 |
| 2 | 50,000 | 300 |
| 3 | 2,000 | 2,000 |

## Verification

With zero noise, the recovered coefficients match the known `beta_true`.
Across all formal measurements, the maximum observed absolute coefficient error
was at most `1e-6`; the reported RMS error rounds to `0.000000`.

The separate pilot with `noise_std=0.5` and `N=p=2000` showed much larger
coefficient differences. This is expected because there are no redundant
observations to average out noise, and solving normal equations can amplify
conditioning effects. It is not used as the correctness criterion.

## Timing results

Each total is the mean of three runs; the value after `±` is the sample
standard deviation in seconds.

### Gaussian elimination

| Compiler | Flag | N | p | XtX (s) | Xty (s) | Solve (s) | Total (s) |
|---|---|---:|---:|---:|---:|---:|---:|
EOF

    awk -F, '
        NR > 1 && $3 == "gaussian" {
            printf "| %s | `%s` | %s | %s | %.6f | %.6f | %.6f | %.6f ± %.6f |\n", \
                $1, $2, $4, $5, $7, $8, $9, $10, $11
        }
    ' "$summary"

    cat <<'EOF'

### Gauss-Jordan elimination

| Compiler | Flag | N | p | XtX (s) | Xty (s) | Solve (s) | Total (s) |
|---|---|---:|---:|---:|---:|---:|---:|
EOF

    awk -F, '
        NR > 1 && $3 == "gauss-jordan" {
            printf "| %s | `%s` | %s | %s | %.6f | %.6f | %.6f | %.6f ± %.6f |\n", \
                $1, $2, $4, $5, $7, $8, $9, $10, $11
        }
    ' "$summary"

    cat <<'EOF'

## Observations

- Configurations 1 and 2 are dominated by the naive `X^T X` computation.
  Their linear systems are relatively small, so solver time is negligible.
- In configuration 3, the `p x p` system is large enough that solver time is
  substantial. Gauss-Jordan is slower than Gaussian elimination because it
  eliminates entries above and below each pivot.
- Optimization substantially improves the compute-heavy kernels. The measured
  values describe this FT3 node and these three repetitions; they should not be
  interpreted as a universal ranking of compilers.
- The raw measurements include run-to-run variation, especially for some
  long-running cases. The report therefore provides both the mean and sample
  standard deviation instead of selecting only the fastest run.

## Reproducibility

Raw data and environment records:

- `results/benchmark-gaussian-9977521.csv`
- `results/benchmark-gauss-jordan-9978508.csv`
- `results/benchmark-summary.csv`
- `results/environment-gaussian-9977521.txt`
- `results/environment-gauss-jordan-9978508.txt`

To repeat the measurements:

```bash
sbatch benchmark.slurm gaussian 3
sbatch benchmark.slurm gauss-jordan 3
bash summarize_results.sh results/benchmark-gaussian-JOBID.csv \
    results/benchmark-gauss-jordan-JOBID.csv
```
EOF
} > "$report"
