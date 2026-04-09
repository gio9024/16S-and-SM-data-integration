#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 3 — MGS Step 2: Classify extracted 16S reads in QIIME2
#
#  Uses the SAME RefSeq 16S database/classifier as the 16S amplicon side,
#  ensuring identical taxonomy labels for cross-method comparison.
#
#  Workflow:
#    1. Create manifest from SortMeRNA-extracted 16S FASTQs
#    2. Import into QIIME2
#    3. DADA2 denoise (to get ASVs)
#    4. Classify with RefSeq 16S full-length NB classifier
#    5. Collapse to genus & export TSV
#
#  Prerequisites:
#    - SortMeRNA step completed (submit_sortmerna_zymo.sh)
#    - conda activate qiime2-amplicon-2024.5
#
#  Usage:
#    conda activate qiime2-amplicon-2024.5
#    bash process_sortmerna_qiime2_zymo.sh
##############################################################################

SMR_DIR="results/pipeline3/MGS/sortmerna"
OUT_DIR="results/pipeline3/MGS"

# Same database as 16S side — RefSeq 16S
REFSEQ_DIR="/DCEG/Projects/Microbiome/Combined_Study/RefSeq-16S"
# Full-length classifier (shotgun 16S fragments can come from any region)
CLASSIFIER="${REFSEQ_DIR}/refseq16s_fullLength_nb.qza"
TAXONOMY_QZA="${REFSEQ_DIR}/refseq16s_taxonomy.qza"

cd "$(dirname "$0")"

echo "=== Pipeline 3 — MGS Step 2: QIIME2 classification of extracted 16S reads ==="
echo "Classifier: ${CLASSIFIER}"
echo ""

# ── Step 1: Create manifest ─────────────────────────────────────────────
echo "=== Step 1: Creating manifest from SortMeRNA output ==="

MANIFEST="${OUT_DIR}/manifest_16S_extracted.tsv"
echo -e "sample-id\tforward-absolute-filepath\treverse-absolute-filepath" > "${MANIFEST}"

PREFIXES=(
    "SC718268_CCGGAATT-ACCGAATG_L001"
    "SC718268_TGGATCAC-GCATTGGT_L001"
    "SC718268_CAACCTAG-AGGTCTGT_L001"
    "SC718268_TCTAACGC-CGCCTTAT_L001"
)

FOUND=0
for PREFIX in "${PREFIXES[@]}"; do
    FWD="${SMR_DIR}/${PREFIX}_16S_fwd.fq.gz"
    REV="${SMR_DIR}/${PREFIX}_16S_rev.fq.gz"

    if [[ -f "$FWD" && -f "$REV" ]]; then
        ABS_FWD="$(cd "$(dirname "$FWD")" && pwd)/$(basename "$FWD")"
        ABS_REV="$(cd "$(dirname "$REV")" && pwd)/$(basename "$REV")"
        echo -e "${PREFIX}\t${ABS_FWD}\t${ABS_REV}" >> "${MANIFEST}"
        FOUND=$((FOUND + 1))
        echo "  Found: ${PREFIX}"
    else
        echo "  WARNING: Missing ${PREFIX} — skipping"
    fi
done

if [[ $FOUND -eq 0 ]]; then
    echo "ERROR: No extracted 16S FASTQ files found in ${SMR_DIR}/"
    echo "Make sure SortMeRNA jobs have completed."
    exit 1
fi
echo "Manifest: ${MANIFEST} (${FOUND} samples)"
echo ""

# ── Step 2: Import into QIIME2 ──────────────────────────────────────────
echo "=== Step 2: Importing extracted 16S reads ==="
qiime tools import \
    --type 'SampleData[PairedEndSequencesWithQuality]' \
    --input-path "${MANIFEST}" \
    --output-path "${OUT_DIR}/16S_extracted_demux.qza" \
    --input-format PairedEndFastqManifestPhred33V2
echo "Done."
echo ""

# ── Step 3: DADA2 denoise ───────────────────────────────────────────────
echo "=== Step 3: DADA2 denoising ==="
echo "Note: Using full 150bp reads (no truncation) since these are"
echo "      random 16S fragments, not amplicon reads."
qiime dada2 denoise-paired \
    --i-demultiplexed-seqs "${OUT_DIR}/16S_extracted_demux.qza" \
    --p-trunc-len-f 0 \
    --p-trunc-len-r 0 \
    --o-table "${OUT_DIR}/dada2_table.qza" \
    --o-representative-sequences "${OUT_DIR}/rep_seqs.qza" \
    --o-denoising-stats "${OUT_DIR}/dada2_stats.qza"
echo "Done."
echo ""

# ── Step 4: Classify with RefSeq 16S NB classifier ──────────────────────
echo "=== Step 4: Classifying ASVs with RefSeq 16S full-length NB classifier ==="
qiime feature-classifier classify-sklearn \
    --i-classifier "${CLASSIFIER}" \
    --i-reads "${OUT_DIR}/rep_seqs.qza" \
    --o-classification "${OUT_DIR}/refseq_taxonomy.qza"
echo "Done."
echo ""

# ── Step 5: Collapse to genus (level 6) ─────────────────────────────────
echo "=== Step 5: Collapsing to genus level ==="
qiime taxa collapse \
    --i-table "${OUT_DIR}/dada2_table.qza" \
    --i-taxonomy "${OUT_DIR}/refseq_taxonomy.qza" \
    --p-level 6 \
    --o-collapsed-table "${OUT_DIR}/table_genus.qza"
echo "Done."
echo ""

# ── Step 6: Export genus table to TSV ────────────────────────────────────
echo "=== Step 6: Exporting genus table ==="
WORKDIR="${OUT_DIR}/export_genus"
mkdir -p "${WORKDIR}"

qiime tools export \
    --input-path "${OUT_DIR}/table_genus.qza" \
    --output-path "${WORKDIR}"

biom convert \
    -i "${WORKDIR}/feature-table.biom" \
    -o "${OUT_DIR}/otu_table_genus.tsv" \
    --to-tsv

# Remove biom comment header
tail -n +2 "${OUT_DIR}/otu_table_genus.tsv" > "${OUT_DIR}/tmp" && \
    mv "${OUT_DIR}/tmp" "${OUT_DIR}/otu_table_genus.tsv"

echo ""
echo "=== Done! ==="
echo ""
echo "Output files in ${OUT_DIR}/:"
echo "  16S_extracted_demux.qza    — imported extracted 16S reads"
echo "  dada2_table.qza            — ASV feature table"
echo "  rep_seqs.qza               — representative sequences"
echo "  refseq_taxonomy.qza        — RefSeq 16S taxonomy assignments"
echo "  table_genus.qza            — genus-level collapsed table"
echo "  otu_table_genus.tsv        — genus-level OTU table (for comparison)"
echo ""
echo "Compare with 16S side:  results/pipeline3/16S/otu_table_genus.tsv"
echo "Both use the SAME RefSeq 16S database and taxonomy."
