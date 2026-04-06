#!/usr/bin/env bash
set -euo pipefail
#
# Submit Bowtie2 alignment jobs for the two Zymo MGS samples via sbatch.
# Each FASTQ pair gets its own SLURM job.
#
# Usage:
#   bash submit_bowtie2_zymo.sh
#

INDEX_PREFIX="/DCEG/Projects/Microbiome/Combined_Study/vol2/bowtie2/WoLr2/WoLr2"
DATA_DIR="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Zymobiomics_Data"
OUT_DIR="results/MGS/alignments"
LOG_DIR="results/MGS/logs"
THREADS=4
MEM="80g"
WALLTIME="3-00:00:00"

SAMPLES=("NP0084-HE41" "NP0084-HE42")

mkdir -p "${OUT_DIR}" "${LOG_DIR}"

for sample in "${SAMPLES[@]}"; do
  for fq1 in "${DATA_DIR}/${sample}"/*_R1_001.fastq.gz; do
    [[ -e "${fq1}" ]] || { echo "No R1 files found for ${sample}" >&2; exit 1; }
    sample_core=$(basename "${fq1}" | sed -E 's/_R1_001\.fastq\.gz$//')
    fq2="${fq1/_R1_/_R2_}"
    if [[ ! -e "${fq2}" ]]; then
      echo "WARNING: missing ${fq2}" >&2
      continue
    fi

    JOB_NAME="bt2_${sample_core}"

    sbatch \
      --partition=cgrq \
      --job-name="${JOB_NAME}" \
      --mem="${MEM}" \
      --cpus-per-task="${THREADS}" \
      --time="${WALLTIME}" \
      --output="${LOG_DIR}/${JOB_NAME}_%j.out" \
      --error="${LOG_DIR}/${JOB_NAME}_%j.err" \
      <<SBATCH_EOF
#!/bin/bash
source /usr/share/modules/init/bash
module load bowtie/2.5.0
bowtie2 -x ${INDEX_PREFIX} --very-sensitive --mm --no-unal \
  -1 ${fq1} -2 ${fq2} \
  -S ${OUT_DIR}/${sample_core}.sam \
  -p ${THREADS}
SBATCH_EOF

    echo "Submitted: ${JOB_NAME}"
  done
done

echo ""
echo "All jobs submitted. Monitor with:  squeue -u \$USER"
