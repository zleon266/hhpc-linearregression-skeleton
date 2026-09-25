#!/bin/bash
#SBATCH --job-name=linreg-benchmark
#SBATCH --partition=medium
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=02:00:00
#SBATCH --output=logs/benchmark-%j.out
#SBATCH --error=logs/benchmark-%j.err

set -euo pipefail
export LC_ALL=C

SOLVER="${1:-gaussian}"
REPEATS="${2:-3}"

if [ "$SOLVER" != "gaussian" ] && [ "$SOLVER" != "gauss-jordan" ]; then
    echo "Solver must be gaussian or gauss-jordan." >&2
    exit 1
fi

mkdir -p bin results
cd "$SLURM_SUBMIT_DIR"

RESULTS="results/benchmark-${SOLVER}-${SLURM_JOB_ID}.csv"
ENVIRONMENT="results/environment-${SOLVER}-${SLURM_JOB_ID}.txt"

{
    echo "Host: $(hostname)"
    echo "Start: $(date)"
    echo "Solver: $SOLVER"
    echo "Repeats: $REPEATS"
    echo
    module load gcc/system
    gcc --version | head -n 1
    module load intel/2021.3.0
    icc --version | head -n 1
    icx --version | head -n 1
} | tee "$ENVIRONMENT"

echo "compiler,opt,solver,N,p,repeat,time_xtx_s,time_xty_s,time_solve_s,time_total_s,max_beta_error,rms_beta_error" > "$RESULTS"

build_compiler() {
    local compiler="$1"
    local cc="$2"

    for opt in O0 O2 O3 Ofast; do
        if [ "$opt" = "O0" ]; then
            flags="-O0"
        else
            flags="-$opt -march=native"
        fi

    make -B TARGET="bin/linreg_${compiler}_${opt}" CC="$cc" OPT="$flags"
    done
}

run_case() {
    local compiler="$1"
    local opt="$2"
    local n="$3"
    local p="$4"
    local repeat="$5"
    local executable="bin/linreg_${compiler}_${opt}"
    local output xtx xty solve total max_error rms_error

    output="$(srun "$executable" "$n" "$p" 42 0.0 "$SOLVER")"
    printf '%s\n' "$output"

    xtx="$(printf '%s\n' "$output" | awk '/^Time XtX:/ {print $3}')"
    xty="$(printf '%s\n' "$output" | awk '/^Time Xty:/ {print $3}')"
    solve="$(printf '%s\n' "$output" | awk '/^Time solve:/ {print $3}')"
    total="$(printf '%s\n' "$output" | awk '/^Time total:/ {print $3}')"
    max_error="$(printf '%s\n' "$output" | awk '/^Max \|beta - beta_true\|:/ {print $5}')"
    rms_error="$(printf '%s\n' "$output" | awk '/^RMS \|beta - beta_true\|:/ {print $5}')"

    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$compiler" "$opt" "$SOLVER" "$n" "$p" "$repeat" \
        "$xtx" "$xty" "$solve" "$total" "$max_error" "$rms_error" \
        >> "$RESULTS"
}

module load gcc/system
build_compiler gcc gcc

module load intel/2021.3.0
build_compiler icc icc
build_compiler icx icx

for compiler in gcc icc icx; do
    for opt in O0 O2 O3 Ofast; do
        for config in "20000 50" "50000 300" "2000 2000"; do
            read -r n p <<< "$config"

            for repeat in $(seq 1 "$REPEATS"); do
                echo "===== $compiler $opt | N=$n p=$p | run $repeat/$REPEATS ====="
                run_case "$compiler" "$opt" "$n" "$p" "$repeat"
            done
        done
    done
done

echo "Results: $RESULTS"
echo "End: $(date)"
