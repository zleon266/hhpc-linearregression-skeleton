#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 RESULTS.csv [RESULTS.csv ...]" >&2
    exit 1
fi

mkdir -p results

{
    echo "compiler,opt,solver,N,p,repeats,mean_xtx_s,mean_xty_s,mean_solve_s,mean_total_s,stddev_total_s,max_beta_error,max_rms_beta_error"

    awk -F, '
        $1 == "compiler" { next }

        {
            key = $1 SUBSEP $2 SUBSEP $3 SUBSEP $4 SUBSEP $5
            count[key]++

            for (i = 7; i <= 10; i++) {
                sum[key, i] += $i
                sumsq[key, i] += $i * $i
            }

            if (($11 + 0) > max_error[key]) max_error[key] = $11
            if (($12 + 0) > max_rms[key]) max_rms[key] = $12
        }

        END {
            for (key in count) {
                split(key, part, SUBSEP)
                n = count[key]

                mean_xtx = sum[key, 7] / n
                mean_xty = sum[key, 8] / n
                mean_solve = sum[key, 9] / n
                mean_total = sum[key, 10] / n

                variance = 0
                if (n > 1) {
                    variance = (sumsq[key, 10] - (sum[key, 10] * sum[key, 10] / n)) / (n - 1)
                }
                if (variance < 0) variance = 0

                printf "%s,%s,%s,%s,%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n", \
                    part[1], part[2], part[3], part[4], part[5], n, \
                    mean_xtx, mean_xty, mean_solve, mean_total, sqrt(variance), \
                    max_error[key], max_rms[key]
            }
        }
    ' "$@" | LC_ALL=C sort -t, -k1,1 -k2,2 -k3,3 -k4,4n -k5,5n
} > results/benchmark-summary.csv
