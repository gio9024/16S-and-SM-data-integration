#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 3 — MGS Step 2: Kraken2/Bracken on SortMeRNA-extracted 16S reads
#
#  Submits Kraken2 sbatch jobs to classify extracted 16S reads against the
#  Kraken2 standard database (full RefSeq). Requires ≥100 GB memory.
#
#  Usage:
#    bash submit_kraken2_p3_zymo.sh
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SMR_DIR="${SCRIPT_DIR}/results/pipeline3/MGS/sortmerna"
K2_DIR="${SCRIPT_DIR}/results/pipeline3/MGS/kraken2"
LOG_DIR="${SCRIPT_DIR}/results/pipeline3/MGS/logs"
K2_DB="/DCEG/Projects/Microbiome/Metagenomics/Kraken/kraken2/k2_standard_20240112"

mkdir -p "${K2_DIR}" "${LOG_DIR}"

PREFIXES=(
    "SC718268_CCGGAATT-ACCGAATG_L001"
    "SC718268_TGGATCAC-GCATTGGT_L001"
    "SC718268_CAACCTAG-AGGTCTGT_L001"
    "SC718268_TCTAACGC-CGCCTTAT_L001"
)

for PREFIX in "${PREFIXES[@]}"; do
    R1="${SMR_DIR}/${PREFIX}_16S_fwd.fq.gz"
    R2="${SMR_DIR}/${PREFIX}_16S_rev.fq.gz"

    if [[ ! -f "$R1" ]]; then
        echo "ERROR: $R1 not found, skipping."
        continue
    fi

    JOB_NAME="k2p3_${PREFIX}"

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

echo "Processing extracted 16S reads: ${PREFIX}"
echo "Database: ${K2_DB}"
echo "Start: \$(date)"

kraken2 \\
    --db ${K2_DB} \\
    --paired ${R1} ${R2} \\
    --gzip-compressed \\
    --output ${K2_DIR}/${PREFIX}.kraken \\
    --report ${K2_DIR}/${PREFIX}.kreport \\
    --threads 8

echo ""
echo "Kraken2 classification stats:"
TOTAL=\$(wc -l < ${K2_DIR}/${PREFIX}.kraken)
CLASSIFIED=\$(grep -c "^C" ${K2_DIR}/${PREFIX}.kraken || true)
echo "  Total reads: \${TOTAL}"
echo "  Classified: \${CLASSIFIED}"
echo "  Unclassified: \$((TOTAL - CLASSIFIED))"
echo ""
echo "Done: ${PREFIX} at \$(date)"
INNER_EOF

    echo "Submitting Kraken2 (extracted 16S) for ${PREFIX}..."
    sbatch "${SBATCH_SCRIPT}"
done

echo ""
echo "All Kraken2 jobs submitted. Monitor with: squeue -u \$USER"
echo "Output will be in: ${K2_DIR}/"
echo "After all jobs finish, run: bash process_bracken_p3_zymo.sh"
