#!/usr/bin/env bash
set -e
# Export 16S DADA2 + GG2 results to genus-level TSV
# Prerequisites: conda activate qiime2-amplicon-2024.5

OUT_DIR="results/16S"
cd "$(dirname "$0")"

echo "=== Collapse 16S table to genus (level 6) ==="
qiime taxa collapse \
  --i-table "${OUT_DIR}/dada2_table.qza" \
  --i-taxonomy "${OUT_DIR}/gg2_taxonomy.qza" \
  --p-level 6 \
  --o-collapsed-table "${OUT_DIR}/table_genus.qza"

echo "=== Export genus-level TSV ==="
WORKDIR="${OUT_DIR}/export_genus"
mkdir -p "${WORKDIR}"

qiime tools export \
  --input-path "${OUT_DIR}/table_genus.qza" \
  --output-path "${WORKDIR}"

biom convert \
  -i "${WORKDIR}/feature-table.biom" \
  -o "${OUT_DIR}/otu_table_genus.tsv" \
  --to-tsv

tail -n +2 "${OUT_DIR}/otu_table_genus.tsv" > "${OUT_DIR}/tmp" && mv "${OUT_DIR}/tmp" "${OUT_DIR}/otu_table_genus.tsv"

echo "Done! Output: ${OUT_DIR}/otu_table_genus.tsv"
