#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 2 — MGS Step 1: Kraken2 classification of Patrick SRA WGS reads
#
#  Classifies full shotgun reads against the Kraken2 standard database
#  (built from full NCBI RefSeq genomes). One sbatch job per sample.
#
#  Input:   DataSets/Patrick_SRA_Data/WGS_RAW/<SRR>_1/2.fastq.gz
#  Output:  results/patrick/pipeline2/MGS/kraken2/<BCH_sample>.kraken/.kreport
#
#  Usage:
#    bash submit_kraken2_p2_patrick.sh
#  After completion:
#    bash process_bracken_p2_patrick.sh
##############################################################################

DATA_DIR="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Patrick_SRA_Data/WGS_RAW"
MAPPING_CSV="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Patrick_SRA_Data/16S_WGS_sample_name_mappings.csv"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/results/patrick/pipeline2/MGS/kraken2"
LOG_DIR="${SCRIPT_DIR}/results/patrick/pipeline2/MGS/logs"
K2_DB="/DCEG/Projects/Microbiome/Metagenomics/Kraken/kraken2/k2_standard_20240112"

mkdir -p "${OUT_DIR}" "${LOG_DIR}"

# CSV columns: WGS_SRR, 16S_SRR, sample_name
while IFS=',' read -r WGS_SRR S16_SRR SAMPLE_NAME; do
    [[ -z "${WGS_SRR}" ]] && continue
    WGS_SRR="${WGS_SRR//$'\r'/}"
    SAMPLE_NAME="${SAMPLE_NAME//$'\r'/}"

    R1="${DATA_DIR}/${WGS_SRR}_1.fastq.gz"
    R2="${DATA_DIR}/${WGS_SRR}_2.fastq.gz"

    if [[ ! -f "${R1}" ]]; then
        echo "ERROR: ${R1} not found, skipping ${SAMPLE_NAME}."
        continue
    fi

    JOB_NAME="k2p2_${SAMPLE_NAME}"
    SBATCH_SCRIPT="${LOG_DIR}/${JOB_NAME}.sbatch"

    cat > "${SBATCH_SCRIPT}" << INNER_EOF
#!/bin/bash
#SBATCH --job-name=${JOB_NAME}
#SBATCH --output=${LOG_DIR}/${JOB_NAME}_%j.out
#SBATCH --error=${LOG_DIR}/${JOB_NAME}_%j.err
#SBATCH --partition=cgrq
#SBATCH --mem=100g
#SBATCH --cpus-per-task=8
#SBATCH --time=1-12:00:00

set -e

module load kraken/2.17.1

echo "Sample:   ${SAMPLE_NAME}  (${WGS_SRR})"
echo "Database: ${K2_DB}"
echo "Start:    \$(date)"

kraken2 \\
    --db ${K2_DB} \\
    --paired ${R1} ${R2} \\
    --gzip-compressed \\
    --output ${OUT_DIR}/${SAMPLE_NAME}.kraken \\
    --report ${OUT_DIR}/${SAMPLE_NAME}.kreport \\
    --threads 8

echo ""
echo "Kraken2 classification stats:"
TOTAL=\$(wc -l < ${OUT_DIR}/${SAMPLE_NAME}.kraken)
CLASSIFIED=\$(grep -c "^C" ${OUT_DIR}/${SAMPLE_NAME}.kraken || true)
echo "  Total reads:    \${TOTAL}"
echo "  Classified:     \${CLASSIFIED}"
echo "  Unclassified:   \$((TOTAL - CLASSIFIED))"
echo ""
echo "Done: ${SAMPLE_NAME} at \$(date)"
INNER_EOF

    echo "Submitting Kraken2 (P2) for ${SAMPLE_NAME}  (${WGS_SRR})..."
    sbatch "${SBATCH_SCRIPT}"
done < "${MAPPING_CSV}"

echo ""
echo "All Kraken2 (P2) jobs submitted. Monitor with: squeue -u \$USER"
echo "Output will be in: ${OUT_DIR}/"
echo "After all jobs finish, run: bash process_bracken_p2_patrick.sh"
