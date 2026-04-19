#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 3 — MGS Step 2: Kraken2 on SortMeRNA-extracted 16S reads
#                           (Patrick SRA Data)
#
#  Submits one sbatch job per sample to classify extracted 16S reads against
#  the Kraken2 standard database. Requires ≥100 GB memory.
#
#  Prerequisites:
#    - SortMeRNA step completed (submit_sortmerna_patrick.sh)
#    - Extracted files: results/patrick/pipeline3/MGS/sortmerna/<BCH_sample>_16S_fwd/rev.fq.gz
#
#  Usage:
#    bash submit_kraken2_p3_patrick.sh
#  After completion:
#    bash process_bracken_p3_patrick.sh
##############################################################################

MAPPING_CSV="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Patrick_SRA_Data/16S_WGS_sample_name_mappings.csv"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SMR_DIR="${SCRIPT_DIR}/results/patrick/pipeline3/MGS/sortmerna"
K2_DIR="${SCRIPT_DIR}/results/patrick/pipeline3/MGS/kraken2"
LOG_DIR="${SCRIPT_DIR}/results/patrick/pipeline3/MGS/logs"
K2_DB="/DCEG/Projects/Microbiome/Metagenomics/Kraken/kraken2/k2_standard_20240112"

mkdir -p "${K2_DIR}" "${LOG_DIR}"

# CSV columns: WGS_SRR, 16S_SRR, sample_name
while IFS=',' read -r WGS_SRR S16_SRR SAMPLE_NAME; do
    [[ -z "${WGS_SRR}" ]] && continue
    SAMPLE_NAME="${SAMPLE_NAME//$'\r'/}"

    R1="${SMR_DIR}/${SAMPLE_NAME}_16S_fwd.fq.gz"
    R2="${SMR_DIR}/${SAMPLE_NAME}_16S_rev.fq.gz"

    if [[ ! -f "${R1}" ]]; then
        echo "ERROR: ${R1} not found, skipping ${SAMPLE_NAME}."
        continue
    fi

    JOB_NAME="k2p3_${SAMPLE_NAME}"
    SBATCH_SCRIPT="${LOG_DIR}/${JOB_NAME}.sbatch"

    cat > "${SBATCH_SCRIPT}" << INNER_EOF
#!/bin/bash
#SBATCH --job-name=${JOB_NAME}
#SBATCH --output=${LOG_DIR}/${JOB_NAME}_%j.out
#SBATCH --error=${LOG_DIR}/${JOB_NAME}_%j.err
#SBATCH --partition=cgrq
#SBATCH --mem=100g
#SBATCH --cpus-per-task=8
#SBATCH --time=1-00:00:00

set -e

module load kraken/2.17.1

echo "Processing extracted 16S reads: ${SAMPLE_NAME}"
echo "Database: ${K2_DB}"
echo "Start: \$(date)"

kraken2 \\
    --db ${K2_DB} \\
    --paired ${R1} ${R2} \\
    --gzip-compressed \\
    --output ${K2_DIR}/${SAMPLE_NAME}.kraken \\
    --report ${K2_DIR}/${SAMPLE_NAME}.kreport \\
    --threads 8

echo ""
echo "Kraken2 classification stats:"
TOTAL=\$(wc -l < ${K2_DIR}/${SAMPLE_NAME}.kraken)
CLASSIFIED=\$(grep -c "^C" ${K2_DIR}/${SAMPLE_NAME}.kraken || true)
echo "  Total reads:    \${TOTAL}"
echo "  Classified:     \${CLASSIFIED}"
echo "  Unclassified:   \$((TOTAL - CLASSIFIED))"
echo ""
echo "Done: ${SAMPLE_NAME} at \$(date)"
INNER_EOF

    echo "Submitting Kraken2 (P3 extracted 16S) for ${SAMPLE_NAME}..."
    sbatch "${SBATCH_SCRIPT}"
done < "${MAPPING_CSV}"

echo ""
echo "All Kraken2 (P3) jobs submitted. Monitor with: squeue -u \$USER"
echo "Output will be in: ${K2_DIR}/"
echo "After all jobs finish, run: bash process_bracken_p3_patrick.sh"
