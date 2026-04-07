#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 3 — MGS Step 2: Kraken2/Bracken classification of extracted 16S
#
#  Runs Kraken2 on extracted 16S reads, then Bracken for genus-level
#  abundance re-estimation, and combines results into a single genus table.
#
#  Prerequisites:
#    - SortMeRNA step completed (submit_sortmerna_zymo.sh)
#    - module load kraken/2.17.1
#
#  Usage:
#    module load kraken/2.17.1
#    bash run_kraken2_zymo.sh
##############################################################################

SMR_DIR="results/pipeline3/MGS/sortmerna"
K2_DIR="results/pipeline3/MGS/kraken2"
BR_DIR="results/pipeline3/MGS/bracken"
OUT_DIR="results/pipeline3/MGS"

K2_DB="/DCEG/Projects/Microbiome/Metagenomics/Kraken/kraken2/k2_standard_20240112"
BRACKEN="/DCEG/Projects/Microbiome/Metagenomics/Kraken/Bracken/bracken"

# RefSeq 16S taxonomy for QIIME2-style labels
REFSEQ_TAXONOMY="/DCEG/Projects/Microbiome/Combined_Study/RefSeq-16S/taxonomy.qiime.derep.tsv"

cd "$(dirname "$0")"
mkdir -p "${K2_DIR}" "${BR_DIR}"

# FASTQ prefixes (must match what SortMeRNA produced)
PREFIXES=(
    "SC718268_CCGGAATT-ACCGAATG_L001"
    "SC718268_TGGATCAC-GCATTGGT_L001"
    "SC718268_CAACCTAG-AGGTCTGT_L001"
    "SC718268_TCTAACGC-CGCCTTAT_L001"
)

echo "=== Step 1: Run Kraken2 on extracted 16S reads ==="
for PREFIX in "${PREFIXES[@]}"; do
    R1="${SMR_DIR}/${PREFIX}_16S_fwd.fastq.gz"
    R2="${SMR_DIR}/${PREFIX}_16S_rev.fastq.gz"

    if [[ ! -f "$R1" ]]; then
        echo "WARNING: $R1 not found, skipping ${PREFIX}"
        continue
    fi

    echo "  Processing: ${PREFIX}"
    kraken2 \
        --db "${K2_DB}" \
        --paired "${R1}" "${R2}" \
        --gzip-compressed \
        --output "${K2_DIR}/${PREFIX}.kraken" \
        --report "${K2_DIR}/${PREFIX}.kreport" \
        --threads 8
done

echo ""
echo "=== Step 2: Run Bracken for genus-level estimates ==="
for PREFIX in "${PREFIXES[@]}"; do
    KREPORT="${K2_DIR}/${PREFIX}.kreport"
    if [[ ! -f "$KREPORT" ]]; then
        echo "WARNING: $KREPORT not found, skipping"
        continue
    fi

    echo "  Processing: ${PREFIX}"
    ${BRACKEN} \
        -d "${K2_DB}" \
        -i "${KREPORT}" \
        -o "${BR_DIR}/${PREFIX}_genus.bracken" \
        -w "${BR_DIR}/${PREFIX}_genus.breport" \
        -r 150 \
        -l G \
        -t 1
done

echo ""
echo "=== Step 3: Combine Bracken genus outputs into a single table ==="

# Build a combined genus table from all Bracken outputs
python3 << 'PYEOF'
import os
import csv
from collections import defaultdict

br_dir = "results/pipeline3/MGS/bracken"
out_file = "results/pipeline3/MGS/otu_table_genus.tsv"

prefixes = [
    "SC718268_CCGGAATT-ACCGAATG_L001",
    "SC718268_TGGATCAC-GCATTGGT_L001",
    "SC718268_CAACCTAG-AGGTCTGT_L001",
    "SC718268_TCTAACGC-CGCCTTAT_L001",
]

# Read NCBI taxonomy ID to name mapping for constructing labels
# Bracken output columns: name, taxonomy_id, taxonomy_lvl, kraken_assigned,
#                         added_reads, new_est_reads, fraction_total_reads
genus_counts = {}  # {sample: {genus_name: count}}

for prefix in prefixes:
    bracken_file = os.path.join(br_dir, f"{prefix}_genus.bracken")
    if not os.path.isfile(bracken_file):
        print(f"WARNING: {bracken_file} not found, skipping")
        continue

    genus_counts[prefix] = {}
    with open(bracken_file) as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            genus = row['name'].strip()
            count = int(float(row['new_est_reads']))
            if count > 0:
                genus_counts[prefix][genus] = count

# Collect all genera across samples
all_genera = sorted(set(g for sample in genus_counts.values() for g in sample))

# Write combined table
with open(out_file, 'w') as f:
    header = ["#OTU ID"] + list(genus_counts.keys())
    f.write('\t'.join(header) + '\n')
    for genus in all_genera:
        row = [genus]
        for prefix in genus_counts:
            row.append(str(genus_counts[prefix].get(genus, 0)))
        f.write('\t'.join(row) + '\n')

print(f"Wrote {len(all_genera)} genera to {out_file}")
PYEOF

echo ""
echo "=== Done ==="
echo "Output files:"
echo "  ${K2_DIR}/*.kreport     (Kraken2 reports)"
echo "  ${BR_DIR}/*_genus.bracken  (Bracken genus estimates)"
echo "  ${OUT_DIR}/otu_table_genus.tsv  (combined genus table)"
