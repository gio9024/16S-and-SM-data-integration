#!/usr/bin/env bash
set -euo pipefail
##############################################################################
#  Pipeline 1 — MGS Step 2: Woltka classification (post-Bowtie2)
#
#  Run AFTER submit_bowtie2_patrick.sh completes.
#  Classifies Bowtie2 SAM alignments using Woltka + GreenGenes2 taxonomy,
#  then imports to QIIME2 and collapses to genus level.
#
#  Prerequisites:
#    - All Bowtie2 jobs finished (SAM files in results/patrick/pipeline1/MGS/alignments/)
#    - conda activate woltka  (for woltka step)
#    - conda activate qiime2-amplicon-2024.5  (for QIIME2 steps)
#
#  Usage:
#    # Step A — Woltka (in woltka environment):
#    conda activate woltka
#    bash process_woltka_patrick.sh --woltka-only
#
#    # Step B — QIIME2 post-processing (in qiime2 environment):
#    conda activate qiime2-amplicon-2024.5
#    bash process_woltka_patrick.sh --qiime2-only
#
#    # Or run both sequentially if both envs are configured:
#    bash process_woltka_patrick.sh
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SAM_DIR="${SCRIPT_DIR}/results/patrick/pipeline1/MGS/alignments"
OUT_DIR="${SCRIPT_DIR}/results/patrick/pipeline1/MGS"
GG2_TAX="/DCEG/Projects/Microbiome/Combined_Study/gg2_refs/taxonomy.tsv"

WOLTKA_ONLY=false
QIIME2_ONLY=false

for arg in "$@"; do
    case $arg in
        --woltka-only) WOLTKA_ONLY=true ;;
        --qiime2-only) QIIME2_ONLY=true ;;
    esac
done

cd "${SCRIPT_DIR}"
mkdir -p "${OUT_DIR}"

# ── Woltka classification ──────────────────────────────────────────────────
if [[ "${QIIME2_ONLY}" == false ]]; then
    echo "=== Woltka: classifying SAM alignments ==="
    echo "Input SAMs: ${SAM_DIR}/"

    # Count available SAM files
    N_SAM=$(ls "${SAM_DIR}"/*.sam 2>/dev/null | wc -l)
    echo "  Found ${N_SAM} SAM file(s)"

    woltka classify \
        -i "${SAM_DIR}" \
        -o "${OUT_DIR}/woltka_out.biom"

    echo "  Woltka done -> ${OUT_DIR}/woltka_out.biom"
fi

# ── QIIME2 taxonomy + export ───────────────────────────────────────────────
if [[ "${WOLTKA_ONLY}" == false ]]; then
    if [[ ! -f "${OUT_DIR}/woltka_out.biom" ]]; then
        echo "ERROR: ${OUT_DIR}/woltka_out.biom not found."
        echo "Run woltka step first: bash process_woltka_patrick.sh --woltka-only"
        exit 1
    fi

    echo "=== Step: Import OGU table to QIIME 2 ==="
    qiime tools import \
        --type 'FeatureTable[Frequency]' \
        --input-path "${OUT_DIR}/woltka_out.biom" \
        --output-path "${OUT_DIR}/ogu_table.qza"

    echo "=== Step: Import GG2 taxonomy ==="
    qiime tools import \
        --type 'FeatureData[Taxonomy]' \
        --input-format TSVTaxonomyFormat \
        --input-path "${GG2_TAX}" \
        --output-path "${OUT_DIR}/ogu_taxonomy.qza"

    echo "=== Step: Filter OGU table to GG2 features ==="
    qiime feature-table filter-features \
        --i-table "${OUT_DIR}/ogu_table.qza" \
        --m-metadata-file "${GG2_TAX}" \
        --o-filtered-table "${OUT_DIR}/ogu_table_gg2.qza"

    echo "=== Step: Collapse to genus (level 6) ==="
    qiime taxa collapse \
        --i-table "${OUT_DIR}/ogu_table_gg2.qza" \
        --i-taxonomy "${OUT_DIR}/ogu_taxonomy.qza" \
        --p-level 6 \
        --o-collapsed-table "${OUT_DIR}/ogu_table_genus.qza"

    echo "=== Step: Export genus-level TSV ==="
    WORKDIR="${OUT_DIR}/export_ogu"
    mkdir -p "${WORKDIR}/genus" "${WORKDIR}/full"

    qiime tools export \
        --input-path "${OUT_DIR}/ogu_table_genus.qza" \
        --output-path "${WORKDIR}/genus"

    biom convert \
        -i "${WORKDIR}/genus/feature-table.biom" \
        -o "${OUT_DIR}/otu_table_genus.tsv" \
        --to-tsv

    tail -n +2 "${OUT_DIR}/otu_table_genus.tsv" > "${OUT_DIR}/tmp" && mv "${OUT_DIR}/tmp" "${OUT_DIR}/otu_table_genus.tsv"

    echo "=== Step: Export full OGU table with taxonomy ==="
    qiime tools export \
        --input-path "${OUT_DIR}/ogu_table_gg2.qza" \
        --output-path "${WORKDIR}/full"

    qiime tools export \
        --input-path "${OUT_DIR}/ogu_taxonomy.qza" \
        --output-path "${WORKDIR}/full"

    biom add-metadata \
        -i "${WORKDIR}/full/feature-table.biom" \
        -o "${WORKDIR}/full/feature-table-with-tax.biom" \
        --observation-metadata-fp "${WORKDIR}/full/taxonomy.tsv" \
        --sc-separated taxonomy \
        --observation-header OTUID,taxonomy,Confidence

    biom convert \
        -i "${WORKDIR}/full/feature-table-with-tax.biom" \
        -o "${OUT_DIR}/otu_table_full.tsv" \
        --to-tsv \
        --header-key taxonomy

    tail -n +2 "${OUT_DIR}/otu_table_full.tsv" > "${OUT_DIR}/tmp" && mv "${OUT_DIR}/tmp" "${OUT_DIR}/otu_table_full.tsv"

    echo ""
    echo "Done!  Output in ${OUT_DIR}/:"
    echo "  otu_table_genus.tsv   (samples x genus, GG2 taxonomy)"
    echo "  otu_table_full.tsv    (samples x OGU + taxonomy)"
fi
