#!/bin/bash
#SBATCH --job-name=p3_qiime2
#SBATCH --output=results/pipeline3/MGS/logs/p3_qiime2_%j.out
#SBATCH --error=results/pipeline3/MGS/logs/p3_qiime2_%j.err
#SBATCH --partition=cgrq
#SBATCH --mem=32g
#SBATCH --cpus-per-task=8
#SBATCH --time=1-00:00:00

set -e

# Activate QIIME2
source /DCEG_Vdrive/Resources/Tools/anaconda/anaconda3-2021.11/etc/profile.d/conda.sh
conda activate qiime2-amplicon-2024.5

cd /DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S-and-SM-data-integration

echo "=== Starting Pipeline 3 MGS QIIME2 processing ==="
echo "Date: $(date)"
echo ""

bash process_sortmerna_qiime2_zymo.sh

echo ""
echo "=== Completed at: $(date) ==="
