#!/usr/bin/env bash
set -euo pipefail
##############################################################################
#  Pipeline 1 — MGS Step 2: Woltka classification (parallel batch approach)
#                           (Patrick SRA Data)
#
#  Woltka processes SAM files sequentially within one job. This script splits
#  all SAMs into N_BATCHES groups, runs woltka on each batch simultaneously
#  on the cluster, then submits a dependent merge+QIIME2 job that:
#    1. Merges per-batch BIOMs → single woltka_out.biom
#    2. Runs full QIIME2 genus collapse + TSV export
#
#  Prerequisites:
#    - Bowtie2 step complete: results/patrick/pipeline1/MGS/alignments/*.sam
#
#  Usage:
#    bash submit_woltka_patrick.sh [N_BATCHES]   (default: 10)
#
#  Monitor:
#    squeue -u $USER
#    tail -f results/patrick/pipeline1/MGS/logs/woltka_pat_merge_<JOBID>.out
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SAM_DIR="${SCRIPT_DIR}/results/patrick/pipeline1/MGS/alignments"
OUT_DIR="${SCRIPT_DIR}/results/patrick/pipeline1/MGS"
LOG_DIR="${OUT_DIR}/logs"
BATCH_BASE="${OUT_DIR}/woltka_batches"
CONDA_BASE="/DCEG_Vdrive/Resources/Tools/anaconda/anaconda3-2021.11"
GG2_TAX="/DCEG/Projects/Microbiome/Combined_Study/gg2_refs/taxonomy.tsv"

N_BATCHES="${1:-10}"

mkdir -p "${LOG_DIR}" "${BATCH_BASE}"

# ── Enumerate SAM files ───────────────────────────────────────────────────────
mapfile -t SAM_FILES < <(ls "${SAM_DIR}"/*.sam 2>/dev/null | sort)
N_TOTAL="${#SAM_FILES[@]}"

if [[ "${N_TOTAL}" -eq 0 ]]; then
    echo "ERROR: No SAM files found in ${SAM_DIR}"
    echo "Run submit_bowtie2_patrick.sh first."
    exit 1
fi

# Clamp N_BATCHES to N_TOTAL
if [[ "${N_BATCHES}" -gt "${N_TOTAL}" ]]; then
    N_BATCHES="${N_TOTAL}"
fi

# Ceiling division for batch size
BATCH_SIZE=$(( (N_TOTAL + N_BATCHES - 1) / N_BATCHES ))

echo "Found ${N_TOTAL} SAM files → splitting into ${N_BATCHES} batches of ~${BATCH_SIZE} each"
echo ""

# ── Submit one woltka job per batch ──────────────────────────────────────────
BATCH_JOB_IDS=()
BATCH_BIOM_FILES=()

for (( B=0; B<N_BATCHES; B++ )); do
    START=$(( B * BATCH_SIZE ))
    [[ ${START} -ge ${N_TOTAL} ]] && break

    BATCH_DIR="${BATCH_BASE}/batch_${B}"
    BATCH_BIOM="${BATCH_BASE}/batch_${B}.biom"

    # (Re)create symlink directory for this batch
    rm -rf "${BATCH_DIR}"
    mkdir -p "${BATCH_DIR}"

    for (( I=START; I<START+BATCH_SIZE && I<N_TOTAL; I++ )); do
        ln -sf "${SAM_FILES[$I]}" "${BATCH_DIR}/$(basename "${SAM_FILES[$I]}")"
    done

    N_IN_BATCH=$(ls "${BATCH_DIR}"/*.sam | wc -l)
    echo "  Batch ${B}: ${N_IN_BATCH} SAMs"

    BATCH_BIOM_FILES+=("${BATCH_BIOM}")

    JOB_NAME="woltka_pat_b${B}"

    JOB_ID=$(sbatch \
        --partition=cgrq \
        --job-name="${JOB_NAME}" \
        --mem=32g \
        --cpus-per-task=2 \
        --time=4:00:00 \
        --output="${LOG_DIR}/${JOB_NAME}_%j.out" \
        --error="${LOG_DIR}/${JOB_NAME}_%j.err" \
        --parsable \
        <<SBATCH_EOF
#!/bin/bash
set -euo pipefail
echo "=== Woltka Batch ${B} ($(ls ${BATCH_DIR}/*.sam | wc -l) SAMs) ==="
echo "Node: \$(hostname)  Start: \$(date)"
echo ""

source "${CONDA_BASE}/etc/profile.d/conda.sh"
conda activate woltka

woltka classify \
    -i "${BATCH_DIR}" \
    -o "${BATCH_BIOM}"

echo ""
echo "Done → ${BATCH_BIOM}"
echo "End: \$(date)"
SBATCH_EOF
)

    BATCH_JOB_IDS+=("${JOB_ID}")
    echo "    → Submitted job ${JOB_ID}"
done

echo ""

# ── Build dependency and biom list strings ────────────────────────────────────
DEP_STRING="afterok:$(IFS=':'; echo "${BATCH_JOB_IDS[*]}")"
BIOM_LIST="${BATCH_BIOM_FILES[*]}"   # space-separated list for biom merge

echo "Batch jobs submitted: [${BATCH_JOB_IDS[*]}]"
echo "Submitting merge+QIIME2 job (runs after ALL batches finish)..."

# ── Submit merge + QIIME2 dependency job ─────────────────────────────────────
MERGE_JOB_ID=$(sbatch \
    --partition=cgrq \
    --job-name="woltka_pat_merge" \
    --mem=64g \
    --cpus-per-task=8 \
    --time=4:00:00 \
    --dependency="${DEP_STRING}" \
    --output="${LOG_DIR}/woltka_pat_merge_%j.out" \
    --error="${LOG_DIR}/woltka_pat_merge_%j.err" \
    --parsable \
    <<SBATCH_EOF
#!/bin/bash
set -euo pipefail
echo "=== Woltka Merge + QIIME2 (Patrick Pipeline 1) ==="
echo "Node: \$(hostname)  Start: \$(date)"
echo ""

source "${CONDA_BASE}/etc/profile.d/conda.sh"

# ── Step 1: Merge all batch BIOMs ────────────────────────────────────────────
conda activate woltka

echo "=== Step 1: Merging ${#BATCH_BIOM_FILES[@]} batch BIOMs ==="
biom merge-otu-tables \
    -i ${BIOM_LIST} \
    -o "${OUT_DIR}/woltka_out.biom"

echo "  Merged BIOM → ${OUT_DIR}/woltka_out.biom"
conda deactivate

# ── Step 2: QIIME2 taxonomy collapse + export ─────────────────────────────────
conda activate qiime2-amplicon-2024.5
echo ""
echo "=== Step 2: QIIME2 taxonomy + genus export ==="

echo "  Importing OGU feature table..."
qiime tools import \
    --type 'FeatureTable[Frequency]' \
    --input-path "${OUT_DIR}/woltka_out.biom" \
    --output-path "${OUT_DIR}/ogu_table.qza"

echo "  Importing GG2 taxonomy..."
qiime tools import \
    --type 'FeatureData[Taxonomy]' \
    --input-format TSVTaxonomyFormat \
    --input-path "${GG2_TAX}" \
    --output-path "${OUT_DIR}/ogu_taxonomy.qza"

echo "  Filtering OGU table to GG2 features..."
qiime feature-table filter-features \
    --i-table "${OUT_DIR}/ogu_table.qza" \
    --m-metadata-file "${GG2_TAX}" \
    --o-filtered-table "${OUT_DIR}/ogu_table_gg2.qza"

echo "  Collapsing to genus (level 6)..."
qiime taxa collapse \
    --i-table "${OUT_DIR}/ogu_table_gg2.qza" \
    --i-taxonomy "${OUT_DIR}/ogu_taxonomy.qza" \
    --p-level 6 \
    --o-collapsed-table "${OUT_DIR}/ogu_table_genus.qza"

echo "  Exporting genus-level TSV..."
WORKDIR="${OUT_DIR}/export_ogu"
mkdir -p "\${WORKDIR}/genus" "\${WORKDIR}/full"

qiime tools export \
    --input-path "${OUT_DIR}/ogu_table_genus.qza" \
    --output-path "\${WORKDIR}/genus"

biom convert \
    -i "\${WORKDIR}/genus/feature-table.biom" \
    -o "${OUT_DIR}/otu_table_genus.tsv" \
    --to-tsv
tail -n +2 "${OUT_DIR}/otu_table_genus.tsv" > "${OUT_DIR}/tmp" && \
    mv "${OUT_DIR}/tmp" "${OUT_DIR}/otu_table_genus.tsv"

echo "  Exporting full OGU table with taxonomy..."
qiime tools export \
    --input-path "${OUT_DIR}/ogu_table_gg2.qza" \
    --output-path "\${WORKDIR}/full"

qiime tools export \
    --input-path "${OUT_DIR}/ogu_taxonomy.qza" \
    --output-path "\${WORKDIR}/full"

biom add-metadata \
    -i "\${WORKDIR}/full/feature-table.biom" \
    -o "\${WORKDIR}/full/feature-table-with-tax.biom" \
    --observation-metadata-fp "\${WORKDIR}/full/taxonomy.tsv" \
    --sc-separated taxonomy \
    --observation-header OTUID,taxonomy,Confidence

biom convert \
    -i "\${WORKDIR}/full/feature-table-with-tax.biom" \
    -o "${OUT_DIR}/otu_table_full.tsv" \
    --to-tsv \
    --header-key taxonomy
tail -n +2 "${OUT_DIR}/otu_table_full.tsv" > "${OUT_DIR}/tmp" && \
    mv "${OUT_DIR}/tmp" "${OUT_DIR}/otu_table_full.tsv"

conda deactivate

echo ""
echo "=== All done!  End: \$(date) ==="
echo ""
echo "Output files:"
echo "  ${OUT_DIR}/woltka_out.biom          (raw merged OGU BIOM)"
echo "  ${OUT_DIR}/otu_table_genus.tsv      (samples x genus, GG2 taxonomy)"
echo "  ${OUT_DIR}/otu_table_full.tsv       (samples x OGU + taxonomy)"
SBATCH_EOF
)

echo "  → Submitted merge+QIIME2 job ${MERGE_JOB_ID}"
echo ""
echo "Pipeline summary:"
echo "  10 parallel woltka jobs [${BATCH_JOB_IDS[*]}]"
echo "       ↓  (all must succeed)"
echo "  merge+QIIME2 job [${MERGE_JOB_ID}]"
echo ""
echo "Monitor:  squeue -u \$USER"
echo "Final log: ${LOG_DIR}/woltka_pat_merge_${MERGE_JOB_ID}.out"
