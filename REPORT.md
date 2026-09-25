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

Acceptance criterion for zero-noise verification:

```text
max |beta - beta_true| <= 1e-5
```

All formal zero-noise runs passed this criterion. The largest observed printed
error was `1e-6`.

## Timing results

Each total is the mean of three runs; the value after `±` is the sample
standard deviation in seconds.

### Gaussian elimination

| Compiler | Flag | N | p | XtX (s) | Xty (s) | Solve (s) | Total (s) |
|---|---|---:|---:|---:|---:|---:|---:|
| gcc | `O0` | 2000 | 2000 | 35.653682 | 0.016502 | 9.416650 | 45.086833 ± 0.039914 |
| gcc | `O0` | 20000 | 50 | 0.371535 | 0.004355 | 0.000180 | 0.376070 ± 0.003413 |
| gcc | `O0` | 50000 | 300 | 33.734520 | 0.089721 | 0.032303 | 33.856544 ± 1.863833 |
| gcc | `O2` | 2000 | 2000 | 18.637714 | 0.007855 | 2.126134 | 20.771702 ± 0.677195 |
| gcc | `O2` | 20000 | 50 | 0.283882 | 0.003164 | 0.000042 | 0.287088 ± 0.000598 |
| gcc | `O2` | 50000 | 300 | 23.674644 | 0.047975 | 0.005114 | 23.727732 ± 0.631967 |
| gcc | `O3` | 2000 | 2000 | 18.474647 | 0.007731 | 1.333116 | 19.815494 ± 0.363604 |
| gcc | `O3` | 20000 | 50 | 0.282461 | 0.003000 | 0.000057 | 0.285518 ± 0.002264 |
| gcc | `O3` | 50000 | 300 | 23.748188 | 0.048834 | 0.003963 | 23.800984 ± 0.599743 |
| gcc | `Ofast` | 2000 | 2000 | 18.593017 | 0.007156 | 1.329981 | 19.930155 ± 0.016187 |
| gcc | `Ofast` | 20000 | 50 | 0.282001 | 0.002721 | 0.000059 | 0.284782 ± 0.003600 |
| gcc | `Ofast` | 50000 | 300 | 23.507270 | 0.047539 | 0.003810 | 23.558619 ± 0.594425 |
| icc | `O0` | 2000 | 2000 | 35.458809 | 0.016780 | 9.402258 | 44.877847 ± 0.110189 |
| icc | `O0` | 20000 | 50 | 0.394176 | 0.005315 | 0.000186 | 0.399677 ± 0.015264 |
| icc | `O0` | 50000 | 300 | 35.609435 | 0.089738 | 0.032337 | 35.731511 ± 0.316254 |
| icc | `O2` | 2000 | 2000 | 18.522217 | 0.007537 | 1.322479 | 19.852233 ± 0.201150 |
| icc | `O2` | 20000 | 50 | 0.313671 | 0.003365 | 0.000077 | 0.317113 ± 0.001812 |
| icc | `O2` | 50000 | 300 | 24.411110 | 0.048043 | 0.002543 | 24.461696 ± 0.338778 |
| icc | `O3` | 2000 | 2000 | 18.620631 | 0.007569 | 1.302036 | 19.930237 ± 0.627786 |
| icc | `O3` | 20000 | 50 | 0.311285 | 0.003346 | 0.000068 | 0.314699 ± 0.001179 |
| icc | `O3` | 50000 | 300 | 23.597839 | 0.047878 | 0.002497 | 23.648213 ± 0.318949 |
| icc | `Ofast` | 2000 | 2000 | 18.657470 | 0.007352 | 1.321120 | 19.985943 ± 0.686321 |
| icc | `Ofast` | 20000 | 50 | 0.294563 | 0.003145 | 0.000070 | 0.297778 ± 0.000736 |
| icc | `Ofast` | 50000 | 300 | 24.116035 | 0.049032 | 0.002447 | 24.167513 ± 0.625921 |
| icx | `O0` | 2000 | 2000 | 35.671884 | 0.016467 | 7.747948 | 43.436299 ± 0.212241 |
| icx | `O0` | 20000 | 50 | 0.387629 | 0.005014 | 0.000149 | 0.392792 ± 0.003553 |
| icx | `O0` | 50000 | 300 | 34.568804 | 0.090693 | 0.026385 | 34.685882 ± 1.360251 |
| icx | `O2` | 2000 | 2000 | 21.001544 | 0.010067 | 1.443504 | 22.455115 ± 0.162103 |
| icx | `O2` | 20000 | 50 | 0.299822 | 0.003078 | 0.000074 | 0.302975 ± 0.004473 |
| icx | `O2` | 50000 | 300 | 23.232134 | 0.048149 | 0.002606 | 23.282890 ± 0.532220 |
| icx | `O3` | 2000 | 2000 | 20.943636 | 0.007578 | 1.527968 | 22.479182 ± 0.123028 |
| icx | `O3` | 20000 | 50 | 0.308892 | 0.003089 | 0.000044 | 0.312024 ± 0.001205 |
| icx | `O3` | 50000 | 300 | 23.041548 | 0.049946 | 0.002598 | 23.094093 ± 0.114629 |
| icx | `Ofast` | 2000 | 2000 | 19.370654 | 0.005829 | 1.096581 | 20.473065 ± 0.401580 |
| icx | `Ofast` | 20000 | 50 | 0.308025 | 0.003185 | 0.000044 | 0.311254 ± 0.000783 |
| icx | `Ofast` | 50000 | 300 | 23.232861 | 0.049686 | 0.002595 | 23.285142 ± 0.331300 |

### Gauss-Jordan elimination

| Compiler | Flag | N | p | XtX (s) | Xty (s) | Solve (s) | Total (s) |
|---|---|---:|---:|---:|---:|---:|---:|
| gcc | `O0` | 2000 | 2000 | 35.221095 | 0.016275 | 14.124852 | 49.362222 ± 0.179999 |
| gcc | `O0` | 20000 | 50 | 0.370378 | 0.004387 | 0.000259 | 0.375024 ± 0.001085 |
| gcc | `O0` | 50000 | 300 | 31.989972 | 0.087703 | 0.047812 | 32.125487 ± 0.253760 |
| gcc | `O2` | 2000 | 2000 | 16.614247 | 0.007310 | 3.339156 | 19.960713 ± 0.150934 |
| gcc | `O2` | 20000 | 50 | 0.271967 | 0.002852 | 0.000069 | 0.274888 ± 0.000950 |
| gcc | `O2` | 50000 | 300 | 22.334187 | 0.046191 | 0.010665 | 22.391044 ± 0.049660 |
| gcc | `O3` | 2000 | 2000 | 16.387886 | 0.006973 | 2.025554 | 18.420414 ± 0.264058 |
| gcc | `O3` | 20000 | 50 | 0.274115 | 0.002869 | 0.000078 | 0.277063 ± 0.002685 |
| gcc | `O3` | 50000 | 300 | 22.354414 | 0.045789 | 0.005592 | 22.405796 ± 0.045596 |
| gcc | `Ofast` | 2000 | 2000 | 16.564820 | 0.006395 | 2.001540 | 18.572756 ± 0.125767 |
| gcc | `Ofast` | 20000 | 50 | 0.275852 | 0.002756 | 0.000079 | 0.278687 ± 0.001714 |
| gcc | `Ofast` | 50000 | 300 | 22.286758 | 0.045253 | 0.005705 | 22.337716 ± 0.150086 |
| icc | `O0` | 2000 | 2000 | 34.939253 | 0.016248 | 14.029644 | 48.985146 ± 0.251710 |
| icc | `O0` | 20000 | 50 | 0.367337 | 0.004432 | 0.000256 | 0.372025 ± 0.001638 |
| icc | `O0` | 50000 | 300 | 31.543896 | 0.089087 | 0.047756 | 31.680739 ± 0.165182 |
| icc | `O2` | 2000 | 2000 | 16.303178 | 0.005824 | 1.755959 | 18.064961 ± 0.230979 |
| icc | `O2` | 20000 | 50 | 0.274623 | 0.002670 | 0.000089 | 0.277382 ± 0.003054 |
| icc | `O2` | 50000 | 300 | 22.591857 | 0.045904 | 0.003500 | 22.641261 ± 0.035352 |
| icc | `O3` | 2000 | 2000 | 16.107878 | 0.006715 | 1.706766 | 17.821358 ± 0.340646 |
| icc | `O3` | 20000 | 50 | 0.274234 | 0.003032 | 0.000089 | 0.277356 ± 0.000434 |
| icc | `O3` | 50000 | 300 | 22.525386 | 0.045840 | 0.003366 | 22.574591 ± 0.064591 |
| icc | `Ofast` | 2000 | 2000 | 16.400844 | 0.006593 | 1.728702 | 18.136139 ± 0.074245 |
| icc | `Ofast` | 20000 | 50 | 0.273893 | 0.002758 | 0.000091 | 0.276742 ± 0.000931 |
| icc | `Ofast` | 50000 | 300 | 22.453167 | 0.045533 | 0.003457 | 22.502157 ± 0.033646 |
| icx | `O0` | 2000 | 2000 | 34.993483 | 0.016247 | 11.588326 | 46.598056 ± 0.086803 |
| icx | `O0` | 20000 | 50 | 0.364283 | 0.004367 | 0.000220 | 0.368870 ± 0.001098 |
| icx | `O0` | 50000 | 300 | 31.763300 | 0.086903 | 0.038933 | 31.889136 ± 0.093792 |
| icx | `O2` | 2000 | 2000 | 19.430963 | 0.009152 | 1.819809 | 21.259924 ± 0.263600 |
| icx | `O2` | 20000 | 50 | 0.274829 | 0.002728 | 0.000085 | 0.277641 ± 0.002026 |
| icx | `O2` | 50000 | 300 | 22.301964 | 0.045798 | 0.003762 | 22.351524 ± 0.024591 |
| icx | `O3` | 2000 | 2000 | 19.322191 | 0.006836 | 1.797223 | 21.126250 ± 0.025216 |
| icx | `O3` | 20000 | 50 | 0.276688 | 0.002839 | 0.000053 | 0.279580 ± 0.001180 |
| icx | `O3` | 50000 | 300 | 22.331937 | 0.048531 | 0.003751 | 22.384219 ± 0.053980 |
| icx | `Ofast` | 2000 | 2000 | 19.324793 | 0.006628 | 1.749897 | 21.081318 ± 0.169056 |
| icx | `Ofast` | 20000 | 50 | 0.278021 | 0.002605 | 0.000053 | 0.280680 ± 0.002570 |
| icx | `Ofast` | 50000 | 300 | 22.152178 | 0.048268 | 0.003762 | 22.204208 ± 0.183552 |

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
bash summarize_results.sh results/benchmark-gaussian-GAUSSIAN_JOBID.csv \
     results/benchmark-gauss-jordan-GAUSS_JORDAN_JOBID.csv

```
