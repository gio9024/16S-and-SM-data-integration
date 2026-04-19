#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 3 — MGS Step 1: Extract 16S reads with SortMeRNA (Patrick SRA)
#
#  Submits one sbatch job per WGS sample. Reads the mapping CSV to resolve
#  WGS SRR accessions and BCH sample names.
#
#  Input:   DataSets/Patrick_SRA_Data/WGS_RAW/<SRR>_1/2.fastq.gz
#  Output:  results/patrick/pipeline3/MGS/sortmerna/<BCH_sample>_16S_fwd/rev.fq.gz
#
#  Usage:
#    bash submit_sortmerna_patrick.sh
#  After completion:
#    bash submit_kraken2_p3_patrick.sh
##############################################################################

DATA_DIR="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Patrick_SRA_Data/WGS_RAW"
MAPPING_CSV="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Patrick_SRA_Data/16S_WGS_sample_name_mappings.csv"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/results/patrick/pipeline3/MGS/sortmerna"
LOG_DIR="${SCRIPT_DIR}/results/patrick/pipeline3/MGS/logs"
SMR_DB="${SCRIPT_DIR}/databases/sortmerna_rRNA/smr_v4.3_default_db.fasta"
CONDA_BASE=$(conda info --base)

if [[ ! -f "${SMR_DB}" ]]; then
    echo "ERROR: SortMeRNA database not found at ${SMR_DB}"
    exit 1
fi

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

    JOB_NAME="smr_${SAMPLE_NAME}"
    OUT_PREFIX="${OUT_DIR}/${SAMPLE_NAME}"
    SBATCH_SCRIPT="${LOG_DIR}/${JOB_NAME}.sbatch"

    cat > "${SBATCH_SCRIPT}" << INNER_EOF
#!/bin/bash
#SBATCH --job-name=${JOB_NAME}
#SBATCH --output=${LOG_DIR}/${JOB_NAME}_%j.out
#SBATCH --error=${LOG_DIR}/${JOB_NAME}_%j.err
#SBATCH --partition=cgrq
#SBATCH --mem=32g
#SBATCH --cpus-per-task=8
#SBATCH --time=1-12:00:00

set -e

# Activate sortmerna environment
source ${CONDA_BASE}/etc/profile.d/conda.sh
conda activate sortmerna

echo "Sample:   ${SAMPLE_NAME}  (${WGS_SRR})"
echo "Database: ${SMR_DB}"
echo "Start:    \$(date)"

# Create a clean workdir for this sample
WORKDIR="${OUT_PREFIX}_workdir"
rm -rf "\${WORKDIR}"
mkdir -p "\${WORKDIR}"

# Run SortMeRNA
sortmerna \\
    --ref ${SMR_DB} \\
    --reads ${R1} \\
    --reads ${R2} \\
    --aligned ${OUT_PREFIX}_16S \\
    --other ${OUT_PREFIX}_non16S \\
    --paired_in \\
    --fastx \\
    --out2 \\
    --threads 8 \\
    --workdir "\${WORKDIR}"

# Compress outputs
gzip -f ${OUT_PREFIX}_16S_fwd.fastq  2>/dev/null || true
gzip -f ${OUT_PREFIX}_16S_rev.fastq  2>/dev/null || true
gzip -f ${OUT_PREFIX}_non16S_fwd.fastq 2>/dev/null || true
gzip -f ${OUT_PREFIX}_non16S_rev.fastq 2>/dev/null || true

# Clean up kvdb workdir
rm -rf "\${WORKDIR}"

# Report counts
echo "16S reads extracted:"
zcat ${OUT_PREFIX}_16S_fwd.fastq.gz 2>/dev/null | wc -l | awk '{print \$1/4, "pairs"}'
echo "Done: ${SAMPLE_NAME} at \$(date)"
INNER_EOF

    echo "Submitting SortMeRNA for ${SAMPLE_NAME}  (${WGS_SRR})..."
    sbatch "${SBATCH_SCRIPT}"
done < "${MAPPING_CSV}"

echo ""
echo "All SortMeRNA jobs submitted. Monitor with: squeue -u \$USER"
echo "Output will be in: ${OUT_DIR}/"
echo "After all jobs finish, run: bash submit_kraken2_p3_patrick.sh"
