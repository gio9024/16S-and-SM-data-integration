#!/usr/bin/env bash
set -e
##############################################################################
#  Step 2:  Woltka classify  +  QIIME 2  taxonomy  +  TSV export
#
#  Run AFTER all Bowtie 2 swarm jobs finish.
#
#  Prerequisites:
#    - SAM files in results/MGS/alignments/
#    - conda activate qiime2-amplicon-2024.10  (or whichever QIIME2 env)
#    - woltka available (conda activate woltka)
#
#  Usage:  bash process_woltka_zymo.sh
##############################################################################

ALIGN_DIR="results/MGS/alignments"
OUT_DIR="results/MGS"
GG2_TAX="/DCEG/Projects/Microbiome/Combined_Study/gg2_refs/taxonomy.tsv"

cd "$(dirname "$0")"

echo "=== Step 2a: Woltka OGU classification ==="
woltka classify \
  -i "${ALIGN_DIR}" \
  -o "${OUT_DIR}/woltka_out.biom"

echo "=== Step 2b: Import OGU table to QIIME 2 ==="
qiime tools import \
  --type 'FeatureTable[Frequency]' \
  --input-path "${OUT_DIR}/woltka_out.biom" \
  --output-path "${OUT_DIR}/ogu_table.qza"

echo "=== Step 2c: Import GG2 taxonomy ==="
qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format TSVTaxonomyFormat \
  --input-path "${GG2_TAX}" \
  --output-path "${OUT_DIR}/ogu_taxonomy.qza"

echo "=== Step 2d: Filter OGU table to GG2 features ==="
qiime feature-table filter-features \
  --i-table "${OUT_DIR}/ogu_table.qza" \
  --m-metadata-file "${GG2_TAX}" \
  --o-filtered-table "${OUT_DIR}/ogu_table_gg2.qza"

echo "=== Step 2e: Collapse to genus (level 6) ==="
qiime taxa collapse \
  --i-table "${OUT_DIR}/ogu_table_gg2.qza" \
  --i-taxonomy "${OUT_DIR}/ogu_taxonomy.qza" \
  --p-level 6 \
  --o-collapsed-table "${OUT_DIR}/ogu_table_genus.qza"

echo "=== Step 2f: Export genus-level TSV ==="
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

echo "=== Step 2g: Export full OGU table with taxonomy ==="
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
echo "  otu_table_genus.tsv   (samples x genus)"
echo "  otu_table_full.tsv    (samples x OGU + taxonomy)"
