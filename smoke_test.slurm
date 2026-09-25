#!/bin/bash
#SBATCH --job-name=linreg-smoke
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --output=logs/smoke-%j.out
#SBATCH --error=logs/smoke-%j.err

set -euo pipefail

echo "Host: $(hostname)"
echo "Start: $(date)"

mkdir -p bin

module load gcc/system
echo "===== GCC ====="
gcc --version | head -n 1
make TARGET=bin/linreg_gcc_smoke CC=gcc OPT=-O0
srun bin/linreg_gcc_smoke 2000 50 42 0.5 gaussian

module load intel/2021.3.0
echo "===== ICC ====="
icc --version | head -n 1
make TARGET=bin/linreg_icc_smoke CC=icc OPT=-O0
srun bin/linreg_icc_smoke 2000 50 42 0.5 gaussian

echo "===== ICX ====="
icx --version | head -n 1
make TARGET=bin/linreg_icx_smoke CC=icx OPT=-O0
srun bin/linreg_icx_smoke 2000 50 42 0.5 gaussian

echo "End: $(date)"
