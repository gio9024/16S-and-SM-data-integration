#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 3 — MGS Step 1: Extract 16S reads with SortMeRNA
##############################################################################

DATA_DIR="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Zymobiomics_Data"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/results/pipeline3/MGS/sortmerna"
LOG_DIR="${SCRIPT_DIR}/results/pipeline3/MGS/logs"
SMR_DB="${SCRIPT_DIR}/databases/sortmerna_rRNA/smr_v4.3_default_db.fasta"
CONDA_BASE=$(conda info --base)

if [[ ! -f "${SMR_DB}" ]]; then
    echo "ERROR: SortMeRNA database not found at ${SMR_DB}"
    exit 1
fi

mkdir -p "${OUT_DIR}" "${LOG_DIR}"

declare -A SAMPLES
SAMPLES[NP0084-HE41]="SC718268_CCGGAATT-ACCGAATG_L001 SC718268_TGGATCAC-GCATTGGT_L001"
SAMPLES[NP0084-HE42]="SC718268_CAACCTAG-AGGTCTGT_L001 SC718268_TCTAACGC-CGCCTTAT_L001"

for SAMPLE in "${!SAMPLES[@]}"; do
    for PREFIX in ${SAMPLES[$SAMPLE]}; do
        R1="${DATA_DIR}/${SAMPLE}/${PREFIX}_R1_001.fastq.gz"
        R2="${DATA_DIR}/${SAMPLE}/${PREFIX}_R2_001.fastq.gz"

        if [[ ! -f "$R1" ]]; then
            echo "ERROR: $R1 not found, skipping."
            continue
        fi

        JOB_NAME="smr_${PREFIX}"
        OUT_PREFIX="${OUT_DIR}/${PREFIX}"

        # Write a proper bash script for sbatch
        SBATCH_SCRIPT="${LOG_DIR}/${JOB_NAME}.sbatch"
        cat > "${SBATCH_SCRIPT}" << INNER_EOF
#!/bin/bash
#SBATCH --job-name=${JOB_NAME}
#SBATCH --output=${LOG_DIR}/${JOB_NAME}_%j.out
#SBATCH --error=${LOG_DIR}/${JOB_NAME}_%j.err
#SBATCH --mem=32g
#SBATCH --cpus-per-task=8
#SBATCH --time=1-00:00:00

set -e

# Activate sortmerna environment
source ${CONDA_BASE}/etc/profile.d/conda.sh
conda activate sortmerna

echo "Processing: ${PREFIX}"
echo "Database: ${SMR_DB}"

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
gzip -f ${OUT_PREFIX}_16S_fwd.fastq 2>/dev/null || true
gzip -f ${OUT_PREFIX}_16S_rev.fastq 2>/dev/null || true
gzip -f ${OUT_PREFIX}_non16S_fwd.fastq 2>/dev/null || true
gzip -f ${OUT_PREFIX}_non16S_rev.fastq 2>/dev/null || true

# Clean up kvdb workdir
rm -rf "\${WORKDIR}"

# Report counts
echo "16S reads extracted:"
zcat ${OUT_PREFIX}_16S_fwd.fastq.gz 2>/dev/null | wc -l | awk '{print \$1/4, "pairs"}'
echo "Done: ${PREFIX}"
INNER_EOF

        echo "Submitting SortMeRNA for ${PREFIX}..."
        sbatch "${SBATCH_SCRIPT}"
    done
done

echo ""
echo "All SortMeRNA jobs submitted. Monitor with: squeue -u \$USER"
echo "Output will be in: ${OUT_DIR}/"
echo "After all jobs finish, run: bash run_kraken2_zymo.sh"
