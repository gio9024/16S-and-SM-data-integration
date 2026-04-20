#!/usr/bin/env bash
set -euo pipefail
##############################################################################
#  Recovery script: resubmit only failed woltka batches + re-chain merge job
#
#  Usage (run AFTER failed jobs are gone from the queue):
#    bash recover_woltka_patrick.sh
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/results/patrick/pipeline1/MGS"
BATCH_BASE="${OUT_DIR}/woltka_batches"
LOG_DIR="${OUT_DIR}/logs"
CONDA_BASE="/DCEG_Vdrive/Resources/Tools/anaconda/anaconda3-2021.11"
GG2_TAX="/DCEG/Projects/Microbiome/Combined_Study/gg2_refs/taxonomy.tsv"

echo "=== Woltka Recovery Script ==="
echo ""

# ── Find which batches succeeded and which failed ─────────────────────────────
ALL_BATCH_BIOMS=()
FAILED_BATCHES=()
RECOVERY_JOB_IDS=()

mapfile -t BATCH_DIRS < <(ls -d "${BATCH_BASE}"/batch_[0-9]* 2>/dev/null | sort -V)

for BATCH_DIR in "${BATCH_DIRS[@]}"; do
    B=$(basename "${BATCH_DIR}" | sed 's/batch_//')
    BIOM="${BATCH_BASE}/batch_${B}.biom"
    ALL_BATCH_BIOMS+=("${BIOM}")
    if [[ -f "${BIOM}" ]]; then
        echo "  batch_${B}: ✅ BIOM exists ($(du -h "${BIOM}" | cut -f1))"
    else
        echo "  batch_${B}: ❌ BIOM missing — will resubmit"
        FAILED_BATCHES+=("${B}")
    fi
done

echo ""
echo "Found ${#FAILED_BATCHES[@]} failed batch(es): [${FAILED_BATCHES[*]:-none}]"
echo ""

if [[ ${#FAILED_BATCHES[@]} -eq 0 ]]; then
    echo "All batches already have BIOMs. Just re-submit the merge job."
fi

# ── Resubmit failed batches with longer walltime ──────────────────────────────
for B in "${FAILED_BATCHES[@]}"; do
    BATCH_DIR="${BATCH_BASE}/batch_${B}"
    BATCH_BIOM="${BATCH_BASE}/batch_${B}.biom"

    if [[ ! -d "${BATCH_DIR}" ]]; then
        echo "ERROR: ${BATCH_DIR} not found. Cannot resubmit batch ${B}."
        continue
    fi

    N_SAM=$(ls "${BATCH_DIR}"/*.sam 2>/dev/null | wc -l)
    JOB_NAME="woltka_pat_rb${B}"

    echo "Submitting recovery batch ${B} (${N_SAM} SAMs, 8h walltime)..."

    JOB_ID=$(sbatch \
        --partition=cgrq \
        --job-name="${JOB_NAME}" \
        --mem=32g \
        --cpus-per-task=2 \
        --time=8:00:00 \
        --output="${LOG_DIR}/${JOB_NAME}_%j.out" \
        --error="${LOG_DIR}/${JOB_NAME}_%j.err" \
        --parsable \
        <<SBATCH_EOF
#!/bin/bash
set -euo pipefail
echo "=== Woltka Recovery Batch ${B} (${N_SAM} SAMs) ==="
echo "Node: \$(hostname)  Start: \$(date)"
echo ""

source "${CONDA_BASE}/etc/profile.d/conda.sh"
conda activate woltka

woltka classify \
    -i "${BATCH_DIR}" \
    -o "${BATCH_BIOM}"

echo "Done → ${BATCH_BIOM}"
echo "End: \$(date)"
SBATCH_EOF
)
    RECOVERY_JOB_IDS+=("${JOB_ID}")
    echo "  → Submitted job ${JOB_ID}"
done

# ── Build full list of all BIOMs (existing + recovery) for merge ───────────────
BIOM_LIST="${ALL_BATCH_BIOMS[*]}"

# ── Submit merge + QIIME2 job ─────────────────────────────────────────────────
echo ""
if [[ ${#RECOVERY_JOB_IDS[@]} -gt 0 ]]; then
    DEP_STRING="afterok:$(IFS=':'; echo "${RECOVERY_JOB_IDS[*]}")"
    echo "Submitting merge+QIIME2 job (depends on recovery jobs: ${RECOVERY_JOB_IDS[*]})..."
else
    DEP_STRING=""
    echo "No failed batches — submitting merge+QIIME2 job immediately..."
fi

SBATCH_ARGS=(
    --partition=cgrq
    --job-name=woltka_pat_merge
    --mem=64g
    --cpus-per-task=8
    --time=4:00:00
    --output="${LOG_DIR}/woltka_pat_merge_recovery_%j.out"
    --error="${LOG_DIR}/woltka_pat_merge_recovery_%j.err"
    --parsable
)
[[ -n "${DEP_STRING}" ]] && SBATCH_ARGS+=(--dependency="${DEP_STRING}")

MERGE_JOB_ID=$(sbatch "${SBATCH_ARGS[@]}" <<SBATCH_EOF
#!/bin/bash
set -euo pipefail
echo "=== Woltka Merge + QIIME2 (Recovery) ==="
echo "Node: \$(hostname)  Start: \$(date)"
echo ""

source "${CONDA_BASE}/etc/profile.d/conda.sh"
conda activate woltka

echo "=== Step 1: Verifying all batch BIOMs exist ==="
MISSING=0
for BIOM in ${BIOM_LIST}; do
    if [[ ! -f "\${BIOM}" ]]; then
        echo "  ERROR: Missing \${BIOM}"
        MISSING=\$((MISSING + 1))
    else
        echo "  OK: \${BIOM}"
    fi
done
if [[ \${MISSING} -gt 0 ]]; then
    echo "ERROR: \${MISSING} BIOM file(s) missing. Aborting."
    exit 1
fi

echo ""
echo "=== Step 2: Merging all batch BIOMs ==="
biom merge-otu-tables \
    -i ${BIOM_LIST} \
    -o "${OUT_DIR}/woltka_out.biom"
echo "  Merged → ${OUT_DIR}/woltka_out.biom"

conda deactivate
conda activate qiime2-amplicon-2024.5

echo ""
echo "=== Step 3: QIIME2 genus collapse + export ==="

qiime tools import \
    --type 'FeatureTable[Frequency]' \
    --input-path "${OUT_DIR}/woltka_out.biom" \
    --output-path "${OUT_DIR}/ogu_table.qza"

qiime tools import \
    --type 'FeatureData[Taxonomy]' \
    --input-format TSVTaxonomyFormat \
    --input-path "${GG2_TAX}" \
    --output-path "${OUT_DIR}/ogu_taxonomy.qza"

qiime feature-table filter-features \
    --i-table "${OUT_DIR}/ogu_table.qza" \
    --m-metadata-file "${GG2_TAX}" \
    --o-filtered-table "${OUT_DIR}/ogu_table_gg2.qza"

qiime taxa collapse \
    --i-table "${OUT_DIR}/ogu_table_gg2.qza" \
    --i-taxonomy "${OUT_DIR}/ogu_taxonomy.qza" \
    --p-level 6 \
    --o-collapsed-table "${OUT_DIR}/ogu_table_genus.qza"

WORKDIR="${OUT_DIR}/export_ogu"
mkdir -p "\${WORKDIR}/genus" "\${WORKDIR}/full"

qiime tools export \
    --input-path "${OUT_DIR}/ogu_table_genus.qza" \
    --output-path "\${WORKDIR}/genus"
biom convert \
    -i "\${WORKDIR}/genus/feature-table.biom" \
    -o "${OUT_DIR}/otu_table_genus.tsv" --to-tsv
tail -n +2 "${OUT_DIR}/otu_table_genus.tsv" > "${OUT_DIR}/tmp" && \
    mv "${OUT_DIR}/tmp" "${OUT_DIR}/otu_table_genus.tsv"

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
    -o "${OUT_DIR}/otu_table_full.tsv" --to-tsv --header-key taxonomy
tail -n +2 "${OUT_DIR}/otu_table_full.tsv" > "${OUT_DIR}/tmp" && \
    mv "${OUT_DIR}/tmp" "${OUT_DIR}/otu_table_full.tsv"

conda deactivate

echo ""
echo "=== All done! End: \$(date) ==="
echo "  ${OUT_DIR}/woltka_out.biom"
echo "  ${OUT_DIR}/otu_table_genus.tsv"
echo "  ${OUT_DIR}/otu_table_full.tsv"
SBATCH_EOF
)

echo "  → Submitted merge+QIIME2 job ${MERGE_JOB_ID}"
echo ""
echo "Monitor: squeue -u \$USER"
echo "Log:     ${LOG_DIR}/woltka_pat_merge_recovery_${MERGE_JOB_ID}.out"
