#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 2 — MGS Step 1: Kraken2 classification of raw shotgun reads
#
#  Classifies full shotgun reads against the Kraken2 standard database
#  (built from full NCBI RefSeq genomes).
#
#  Usage:
#    bash submit_kraken2_p2_zymo.sh
##############################################################################

DATA_DIR="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Zymobiomics_Data"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/results/pipeline2/MGS/kraken2"
LOG_DIR="${SCRIPT_DIR}/results/pipeline2/MGS/logs"
K2_DB="/DCEG/Projects/Microbiome/Metagenomics/Kraken/kraken2/k2_standard_20240112"
CONDA_BASE=$(conda info --base)

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

        JOB_NAME="k2p2_${PREFIX}"

        SBATCH_SCRIPT="${LOG_DIR}/${JOB_NAME}.sbatch"
        cat > "${SBATCH_SCRIPT}" << INNER_EOF
#!/bin/bash
#SBATCH --job-name=${JOB_NAME}
#SBATCH --output=${LOG_DIR}/${JOB_NAME}_%j.out
#SBATCH --error=${LOG_DIR}/${JOB_NAME}_%j.err
#SBATCH --partition=cgrq
#SBATCH --mem=64g
#SBATCH --cpus-per-task=8
#SBATCH --time=1-00:00:00

set -e

module load kraken/2.17.1

echo "Processing: ${PREFIX}"
echo "Database: ${K2_DB}"
echo "Start: \$(date)"

kraken2 \\
    --db ${K2_DB} \\
    --paired ${R1} ${R2} \\
    --gzip-compressed \\
    --output ${OUT_DIR}/${PREFIX}.kraken \\
    --report ${OUT_DIR}/${PREFIX}.kreport \\
    --threads 8

echo ""
echo "Kraken2 classification stats:"
TOTAL=\$(wc -l < ${OUT_DIR}/${PREFIX}.kraken)
CLASSIFIED=\$(grep -c "^C" ${OUT_DIR}/${PREFIX}.kraken || true)
echo "  Total reads: \${TOTAL}"
echo "  Classified: \${CLASSIFIED}"
echo "  Unclassified: \$((TOTAL - CLASSIFIED))"
echo ""
echo "Done: ${PREFIX} at \$(date)"
INNER_EOF

        echo "Submitting Kraken2 for ${PREFIX}..."
        sbatch "${SBATCH_SCRIPT}"
    done
done

echo ""
echo "All Kraken2 jobs submitted. Monitor with: squeue -u \$USER"
echo "Output will be in: ${OUT_DIR}/"
echo "After all jobs finish, run: bash process_bracken_p2_zymo.sh"
