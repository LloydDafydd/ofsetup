#!/bin/bash

#SBATCH --job-name=compileoF
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --time=00-02:00:00
#SBATCH --output=test_case_%j.out
#SBATCH --error=test_case_%j.err

./Allwmake -q -j
