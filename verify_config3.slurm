#!/bin/bash
#SBATCH --job-name=linreg-verify-p2000
#SBATCH --partition=medium
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --output=logs/verify-p2000-%j.out
#SBATCH --error=logs/verify-p2000-%j.err

set -euo pipefail

mkdir -p bin

echo "Host: $(hostname)"
echo "Start: $(date)"

module load gcc/system
gcc --version | head -n 1

make TARGET=bin/linreg_gcc_O0_pilot CC=gcc OPT=-O0
srun bin/linreg_gcc_O0_pilot 2000 2000 42 0.0 gaussian

echo "End: $(date)"
