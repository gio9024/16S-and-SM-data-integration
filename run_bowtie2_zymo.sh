#!/usr/bin/env bash
set -euo pipefail
#
# Step 1:  Generate a swarm file of Bowtie 2 commands for the two Zymo MGS
#          samples, then submit to SLURM.
#
# Usage:
#   bash run_bowtie2_zymo.sh
#   swarm -f bowtie2_zymo.swarm -g 80 -t 4 --time 3-00:00:00 \
#         --module bowtie/2.5.0 --logdir results/MGS/logs
#

INDEX_PREFIX="/DCEG/Projects/Microbiome/Combined_Study/vol2/bowtie2/WoLr2/WoLr2"
DATA_DIR="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Zymobiomics_Data"
OUT_DIR="results/MGS/alignments"
THREADS=4

SAMPLES=("NP0084-HE41" "NP0084-HE42")

mkdir -p "${OUT_DIR}" results/MGS/logs

> bowtie2_zymo.swarm

for sample in "${SAMPLES[@]}"; do
  for fq1 in "${DATA_DIR}/${sample}"/*_R1_001.fastq.gz; do
    [[ -e "${fq1}" ]] || { echo "No R1 files found for ${sample}" >&2; exit 1; }
    sample_core=$(basename "${fq1}" | sed -E 's/_R1_001\.fastq\.gz$//')
    fq2="${fq1/_R1_/_R2_}"
    if [[ ! -e "${fq2}" ]]; then
      echo "WARNING: missing ${fq2}" >&2
      continue
    fi
    echo "bowtie2 -x ${INDEX_PREFIX} --very-sensitive --mm --no-unal -1 ${fq1} -2 ${fq2} -S ${OUT_DIR}/${sample_core}.sam -p ${THREADS}"
  done
done > bowtie2_zymo.swarm

echo "Created bowtie2_zymo.swarm with $(wc -l < bowtie2_zymo.swarm) commands."
echo ""
echo "Submit with:"
echo "  swarm -f bowtie2_zymo.swarm -g 80 -t 4 --time 3-00:00:00 --module bowtie/2.5.0 --logdir results/MGS/logs"
