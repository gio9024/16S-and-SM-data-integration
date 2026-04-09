#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 2 — MGS Step 2: Bracken genus-level estimation + combine results
#
#  Runs Bracken on Kraken2 reports to re-estimate genus-level abundances,
#  then combines all library-level Bracken outputs into a single genus table.
#
#  Prerequisites:
#    - Kraken2 step completed (submit_kraken2_p2_zymo.sh)
#    - module load kraken/2.17.1  (for Bracken)
#
#  Usage:
#    module load kraken/2.17.1
#    bash process_bracken_p2_zymo.sh
##############################################################################

K2_DIR="results/pipeline2/MGS/kraken2"
BR_DIR="results/pipeline2/MGS/bracken"
OUT_DIR="results/pipeline2/MGS"

K2_DB="/DCEG/Projects/Microbiome/Metagenomics/Kraken/kraken2/k2_standard_20240112"
BRACKEN="/DCEG/Projects/Microbiome/Metagenomics/Kraken/Bracken/bracken"

cd "$(dirname "$0")"
mkdir -p "${BR_DIR}"

PREFIXES=(
    "SC718268_CCGGAATT-ACCGAATG_L001"
    "SC718268_TGGATCAC-GCATTGGT_L001"
    "SC718268_CAACCTAG-AGGTCTGT_L001"
    "SC718268_TCTAACGC-CGCCTTAT_L001"
)

echo "=== Pipeline 2 — MGS Step 2: Bracken genus-level estimation ==="
echo ""

# ── Step 1: Run Bracken ─────────────────────────────────────────────────
echo "=== Step 1: Run Bracken for genus-level estimates ==="
for PREFIX in "${PREFIXES[@]}"; do
    KREPORT="${K2_DIR}/${PREFIX}.kreport"
    if [[ ! -f "$KREPORT" ]]; then
        echo "  WARNING: $KREPORT not found, skipping"
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

# ── Step 2: Combine Bracken outputs into genus table ─────────────────────
echo "=== Step 2: Combining Bracken genus outputs into a single table ==="

python3 << 'PYEOF'
import os
import csv

br_dir = "results/pipeline2/MGS/bracken"
out_file = "results/pipeline2/MGS/otu_table_genus.tsv"

prefixes = [
    "SC718268_CCGGAATT-ACCGAATG_L001",
    "SC718268_TGGATCAC-GCATTGGT_L001",
    "SC718268_CAACCTAG-AGGTCTGT_L001",
    "SC718268_TCTAACGC-CGCCTTAT_L001",
]

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
echo "  ${K2_DIR}/*.kreport          (Kraken2 reports)"
echo "  ${BR_DIR}/*_genus.bracken    (Bracken genus estimates)"
echo "  ${OUT_DIR}/otu_table_genus.tsv  (combined genus table for comparison)"
echo ""
echo "Compare with 16S side: results/pipeline3/16S/otu_table_genus.tsv"
echo "Both sides use NCBI taxonomy (genus names match directly)."
