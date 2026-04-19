#!/usr/bin/env bash
set -euo pipefail
##############################################################################
#  Pipeline 1 — MGS Step 1: Bowtie2 alignment of Patrick SRA WGS reads
#
#  Aligns paired-end WGS reads against the WoLr2 reference database.
#  Each SRR sample gets its own SLURM job.
#
#  Input:   DataSets/Patrick_SRA_Data/WGS_RAW/<SRR>_1.fastq.gz
#  Output:  results/patrick/pipeline1/MGS/alignments/<BCH_sample>.sam
#
#  Usage:
#    bash submit_bowtie2_patrick.sh
##############################################################################

INDEX_PREFIX="/DCEG/Projects/Microbiome/Combined_Study/vol2/bowtie2/WoLr2/WoLr2"
DATA_DIR="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Patrick_SRA_Data/WGS_RAW"
MAPPING_CSV="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Patrick_SRA_Data/16S_WGS_sample_name_mappings.csv"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/results/patrick/pipeline1/MGS/alignments"
LOG_DIR="${SCRIPT_DIR}/results/patrick/pipeline1/MGS/logs"
THREADS=8
MEM="80g"
WALLTIME="3-00:00:00"

mkdir -p "${OUT_DIR}" "${LOG_DIR}"

# CSV columns: WGS_SRR, 16S_SRR, sample_name
while IFS=',' read -r WGS_SRR S16_SRR SAMPLE_NAME; do
    [[ -z "${WGS_SRR}" ]] && continue
    # Strip carriage returns (Windows line endings)
    WGS_SRR="${WGS_SRR//$'\r'/}"
    SAMPLE_NAME="${SAMPLE_NAME//$'\r'/}"

    FQ1="${DATA_DIR}/${WGS_SRR}_1.fastq.gz"
    FQ2="${DATA_DIR}/${WGS_SRR}_2.fastq.gz"

    if [[ ! -f "${FQ1}" ]]; then
        echo "WARNING: ${FQ1} not found, skipping ${SAMPLE_NAME}" >&2
        continue
    fi
    if [[ ! -f "${FQ2}" ]]; then
        echo "WARNING: ${FQ2} not found, skipping ${SAMPLE_NAME}" >&2
        continue
    fi

    JOB_NAME="bt2_${SAMPLE_NAME}"

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
  -1 ${FQ1} -2 ${FQ2} \
  -S ${OUT_DIR}/${SAMPLE_NAME}.sam \
  -p ${THREADS}
SBATCH_EOF

    echo "Submitted: ${JOB_NAME}  (${WGS_SRR} -> ${SAMPLE_NAME})"
done < "${MAPPING_CSV}"

echo ""
echo "All Bowtie2 jobs submitted. Monitor with:  squeue -u \$USER"
echo "Output will be in: ${OUT_DIR}/"
echo "After all jobs finish, run the Woltka classification step."
