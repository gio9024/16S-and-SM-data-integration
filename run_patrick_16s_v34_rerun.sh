#!/bin/bash
##############################################################################
# Patrick 16S V3-V4 Rerun — Direct QIIME2 Script
#
# ROOT CAUSE: Patrick 16S data uses V3-V4 primers (341F/805R, ~460bp amplicon)
# but DADA2 was run with V4 truncation settings (150/150), causing a ~160bp
# gap between reads and 0.13% merge rate (99.87% reads lost).
#
# FIX: Re-run DADA2 with trunc-len-f=240, trunc-len-r=200 for proper V3-V4
# overlap (~20bp). Results saved to 16S_v34_rerun/ directories.
#
# This script runs:
#   1. Pipeline 1: DADA2 (corrected) + GG2 classifier → genus table
#   2. Pipeline 3: RefSeq full-length classifier on same ASVs → genus table
#   3. DADA2 statistics verification
#
# Usage:
#   sinteractive --mem=32g --cpus-per-task=8 --time=4:00:00
#   conda activate qiime2-amplicon-2024.5
#   bash run_patrick_16s_v34_rerun.sh
##############################################################################

set -euo pipefail

WORKDIR="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S-and-SM-data-integration"
cd "$WORKDIR"

# ── Configuration ─────────────────────────────────────────────────────────────
DATA_DIR="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Patrick_SRA_Data/16S_RAW"
MAPPING_CSV="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Patrick_SRA_Data/16S_WGS_sample_name_mappings.csv"
GG2_CLASSIFIER="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S/2024.09.backbone.v4.nb.qza"
REFSEQ_CLASSIFIER="/DCEG/Projects/Microbiome/Combined_Study/RefSeq-16S/refseq16s_fullLength_nb.qza"

P1_OUT="results/patrick/pipeline1/16S_v34_rerun"
P3_OUT="results/patrick/pipeline3/16S_v34_rerun"

# DADA2 truncation parameters for V3-V4 (341F/805R)
TRUNC_F=240  # Forward: good quality through pos 240 (median Q=37)
TRUNC_R=200  # Reverse: conservative cut at 200 (mean Q=33.4)
# Coverage: 240 + 200 = 440bp; V3-V4 insert ~420bp → ~20bp overlap ✓

THREADS=8

echo "================================================================"
echo "  Patrick 16S V3-V4 Rerun"
echo "  Date: $(date)"
echo "  DADA2 truncation: F=${TRUNC_F}, R=${TRUNC_R}"
echo "  Threads: ${THREADS}"
echo "================================================================"

mkdir -p "$P1_OUT" "$P3_OUT"

# ══════════════════════════════════════════════════════════════════════════════
# Step 1: Generate manifest
# ══════════════════════════════════════════════════════════════════════════════
if [ -f "$P1_OUT/manifest.tsv" ]; then
    echo "[Step 1] manifest.tsv already exists — skipping"
else
    echo "[Step 1] Generating manifest..."
    python3 -c "
import os, csv

data_dir = '${DATA_DIR}'
mapping_csv = '${MAPPING_CSV}'
out = '${P1_OUT}/manifest.tsv'

sample_map = {}
with open(mapping_csv) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        parts = line.split(',')
        if len(parts) >= 3:
            wgs_srr, s16_srr, bch_name = parts[0].strip(), parts[1].strip(), parts[2].strip()
            fq1 = os.path.join(data_dir, f'{s16_srr}_1.fastq.gz')
            if os.path.exists(fq1):
                sample_map[bch_name] = s16_srr

with open(out, 'w') as f:
    f.write('sample-id\tforward-absolute-filepath\treverse-absolute-filepath\n')
    count = 0
    for bch_name, srr in sample_map.items():
        r1 = os.path.abspath(os.path.join(data_dir, f'{srr}_1.fastq.gz'))
        r2 = os.path.abspath(os.path.join(data_dir, f'{srr}_2.fastq.gz'))
        if os.path.exists(r1) and os.path.exists(r2):
            f.write(f'{bch_name}\t{r1}\t{r2}\n')
            count += 1

print(f'  Manifest: {count} samples written to {out}')
"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 2: QIIME2 Import (or reuse existing demux.qza)
# ══════════════════════════════════════════════════════════════════════════════
if [ -f "$P1_OUT/demux.qza" ]; then
    echo "[Step 2] demux.qza already exists — skipping import"
    # Check if it's a symlink to the old run
    if [ -L "$P1_OUT/demux.qza" ]; then
        echo "  (symlinked from original run — same raw reads)"
    fi
else
    echo "[Step 2] Importing reads into QIIME2..."
    qiime tools import \
        --type 'SampleData[PairedEndSequencesWithQuality]' \
        --input-path "$P1_OUT/manifest.tsv" \
        --output-path "$P1_OUT/demux.qza" \
        --input-format PairedEndFastqManifestPhred33V2
    echo "  Done — $(ls -lh "$P1_OUT/demux.qza" | awk '{print $5}')"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 3: DADA2 denoise-paired (THE KEY FIX: 240/200 instead of 150/150)
# ══════════════════════════════════════════════════════════════════════════════
if [ -f "$P1_OUT/dada2_table.qza" ] && [ -f "$P1_OUT/rep_seqs.qza" ] && [ -f "$P1_OUT/dada2_stats.qza" ]; then
    echo "[Step 3] DADA2 outputs already exist — skipping"
else
    echo "[Step 3] Running DADA2 denoise-paired (trunc-f=$TRUNC_F, trunc-r=$TRUNC_R)..."
    echo "  This may take 20-40 minutes for 107 samples..."
    
    qiime dada2 denoise-paired \
        --i-demultiplexed-seqs "$P1_OUT/demux.qza" \
        --p-trunc-len-f $TRUNC_F \
        --p-trunc-len-r $TRUNC_R \
        --o-table "$P1_OUT/dada2_table.qza" \
        --o-representative-sequences "$P1_OUT/rep_seqs.qza" \
        --o-denoising-stats "$P1_OUT/dada2_stats.qza" \
        --p-n-threads $THREADS
    
    echo "  DADA2 complete!"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 3b: Verify DADA2 merge improvement
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "================================================================"
echo "  DADA2 Denoising Statistics (V3-V4 corrected)"
echo "================================================================"

python3 -c "
import zipfile

qza_path = '${P1_OUT}/dada2_stats.qza'
with zipfile.ZipFile(qza_path) as z:
    for name in z.namelist():
        if name.endswith('stats.tsv'):
            with z.open(name) as f:
                content = f.read().decode()
                lines = content.strip().split('\n')
                
                total_input = 0
                total_filtered = 0
                total_merged = 0
                total_nonchim = 0
                n_zero_merge = 0
                n_samples = 0
                per_sample = []
                
                for line in lines[2:]:
                    parts = line.split('\t')
                    if len(parts) >= 9:
                        n_samples += 1
                        inp = int(parts[1])
                        filt = int(parts[2])
                        merged = int(parts[5])
                        nonchim = int(parts[7])
                        total_input += inp
                        total_filtered += filt
                        total_merged += merged
                        total_nonchim += nonchim
                        if merged == 0:
                            n_zero_merge += 1
                        per_sample.append((parts[0], inp, filt, merged, nonchim))
                
                print(f'  Samples:             {n_samples}')
                print(f'  Input reads:         {total_input:>12,}')
                print(f'  Filtered reads:      {total_filtered:>12,} ({total_filtered/total_input*100:.1f}%)')
                print(f'  Merged reads:        {total_merged:>12,} ({total_merged/total_input*100:.1f}%)')
                print(f'  Non-chimeric:        {total_nonchim:>12,} ({total_nonchim/total_input*100:.1f}%)')
                print(f'  Merge rate:          {total_merged/total_filtered*100:.1f}%')
                print(f'  Zero-merge samples:  {n_zero_merge}/{n_samples}')
                
                print()
                print(f'  ┌─────────────────────────────────────────────────┐')
                print(f'  │  COMPARISON — Old (V4 trunc) → New (V3-V4)     │')
                print(f'  │  Merge rate:   0.13% → {total_merged/total_filtered*100:.1f}%')
                print(f'  │  Non-chimeric: 14,882 → {total_nonchim:,}')
                if total_nonchim > 14882:
                    improvement = total_nonchim / 14882
                    print(f'  │  Improvement:  {improvement:.0f}x more reads retained')
                print(f'  └─────────────────────────────────────────────────┘')
                
                # Show worst 5 and best 5 samples
                per_sample.sort(key=lambda x: x[3])  # sort by merged
                print()
                print('  Worst 5 samples (by merged reads):')
                for s, i, f, m, nc in per_sample[:5]:
                    print(f'    {s}: input={i:,} filtered={f:,} merged={m:,} non-chim={nc:,}')
                print()
                print('  Best 5 samples (by merged reads):')
                for s, i, f, m, nc in per_sample[-5:]:
                    print(f'    {s}: input={i:,} filtered={f:,} merged={m:,} non-chim={nc:,}')
"

# ══════════════════════════════════════════════════════════════════════════════
# Step 4: Pipeline 1 — GG2 Classification
# ══════════════════════════════════════════════════════════════════════════════
if [ -f "$P1_OUT/gg2_taxonomy.qza" ]; then
    echo ""
    echo "[Step 4] GG2 classification already exists — skipping"
else
    echo ""
    echo "[Step 4] Classifying ASVs with GreenGenes2..."
    qiime feature-classifier classify-sklearn \
        --i-classifier "$GG2_CLASSIFIER" \
        --i-reads "$P1_OUT/rep_seqs.qza" \
        --o-classification "$P1_OUT/gg2_taxonomy.qza" \
        --p-n-jobs $THREADS
    echo "  GG2 classification complete!"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 5: Pipeline 1 — Collapse to genus + export TSV
# ══════════════════════════════════════════════════════════════════════════════
if [ -f "$P1_OUT/otu_table_genus.tsv" ]; then
    echo "[Step 5] P1 genus table already exists — skipping"
else
    echo "[Step 5] Collapsing to genus level (Pipeline 1)..."
    qiime taxa collapse \
        --i-table "$P1_OUT/dada2_table.qza" \
        --i-taxonomy "$P1_OUT/gg2_taxonomy.qza" \
        --p-level 6 \
        --o-collapsed-table "$P1_OUT/table_genus.qza"
    
    echo "  Exporting to TSV..."
    EXPORT_DIR="$P1_OUT/export_genus"
    mkdir -p "$EXPORT_DIR"
    qiime tools export \
        --input-path "$P1_OUT/table_genus.qza" \
        --output-path "$EXPORT_DIR"
    biom convert \
        -i "$EXPORT_DIR/feature-table.biom" \
        -o "$P1_OUT/otu_table_genus.tsv" \
        --to-tsv
    tail -n +2 "$P1_OUT/otu_table_genus.tsv" > "$P1_OUT/otu_table_genus.tsv.tmp" && \
        mv "$P1_OUT/otu_table_genus.tsv.tmp" "$P1_OUT/otu_table_genus.tsv"
    
    echo "  P1 genus table: $(wc -l < "$P1_OUT/otu_table_genus.tsv") rows"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 6: Pipeline 3 — RefSeq Classification (full-length classifier)
# ══════════════════════════════════════════════════════════════════════════════
if [ -f "$P3_OUT/refseq_taxonomy.qza" ]; then
    echo ""
    echo "[Step 6] RefSeq classification already exists — skipping"
else
    echo ""
    echo "[Step 6] Classifying ASVs with RefSeq 16S full-length classifier..."
    qiime feature-classifier classify-sklearn \
        --i-classifier "$REFSEQ_CLASSIFIER" \
        --i-reads "$P1_OUT/rep_seqs.qza" \
        --o-classification "$P3_OUT/refseq_taxonomy.qza" \
        --p-n-jobs $THREADS
    echo "  RefSeq classification complete!"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 7: Pipeline 3 — Collapse to genus + export TSV
# ══════════════════════════════════════════════════════════════════════════════
if [ -f "$P3_OUT/otu_table_genus.tsv" ]; then
    echo "[Step 7] P3 genus table already exists — skipping"
else
    echo "[Step 7] Collapsing to genus level (Pipeline 3)..."
    qiime taxa collapse \
        --i-table "$P1_OUT/dada2_table.qza" \
        --i-taxonomy "$P3_OUT/refseq_taxonomy.qza" \
        --p-level 6 \
        --o-collapsed-table "$P3_OUT/table_genus.qza"
    
    echo "  Exporting to TSV..."
    EXPORT_DIR="$P3_OUT/export_genus"
    mkdir -p "$EXPORT_DIR"
    qiime tools export \
        --input-path "$P3_OUT/table_genus.qza" \
        --output-path "$EXPORT_DIR"
    biom convert \
        -i "$EXPORT_DIR/feature-table.biom" \
        -o "$P3_OUT/otu_table_genus.tsv" \
        --to-tsv
    tail -n +2 "$P3_OUT/otu_table_genus.tsv" > "$P3_OUT/otu_table_genus.tsv.tmp" && \
        mv "$P3_OUT/otu_table_genus.tsv.tmp" "$P3_OUT/otu_table_genus.tsv"
    
    echo "  P3 genus table: $(wc -l < "$P3_OUT/otu_table_genus.tsv") rows"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "================================================================"
echo "  RERUN COMPLETE — $(date)"
echo "================================================================"
echo ""
echo "  Pipeline 1 (GG2) output:"
echo "    $P1_OUT/otu_table_genus.tsv"
if [ -f "$P1_OUT/otu_table_genus.tsv" ]; then
    echo "    $(wc -l < "$P1_OUT/otu_table_genus.tsv") genera detected"
fi
echo ""
echo "  Pipeline 3 (RefSeq) output:"
echo "    $P3_OUT/otu_table_genus.tsv"
if [ -f "$P3_OUT/otu_table_genus.tsv" ]; then
    echo "    $(wc -l < "$P3_OUT/otu_table_genus.tsv") genera detected"
fi
echo ""
echo "  Original (bad, trunc=150/150) results preserved at:"
echo "    results/patrick/pipeline1/16S/"
echo "    results/patrick/pipeline3/16S/"
echo ""
echo "  To update the report, copy the new genus tables over:"
echo "    cp $P1_OUT/otu_table_genus.tsv results/patrick/pipeline1/16S/otu_table_genus.tsv"
echo "    cp $P3_OUT/otu_table_genus.tsv results/patrick/pipeline3/16S/otu_table_genus.tsv"
echo "================================================================"
