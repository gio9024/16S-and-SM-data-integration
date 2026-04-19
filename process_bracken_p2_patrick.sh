#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 2 — MGS Step 2: Bracken genus estimation + combine results
#                           (Patrick SRA Data)
#
#  Runs Bracken on Kraken2 reports to re-estimate genus-level abundances,
#  then combines all sample-level outputs into a single genus table.
#
#  Prerequisites:
#    - Kraken2 step completed (submit_kraken2_p2_patrick.sh)
#    - module load kraken/2.17.1  (provides bracken)
#
#  Usage:
#    module load kraken/2.17.1
#    bash process_bracken_p2_patrick.sh
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAPPING_CSV="/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/DataSets/Patrick_SRA_Data/16S_WGS_sample_name_mappings.csv"
K2_DIR="${SCRIPT_DIR}/results/patrick/pipeline2/MGS/kraken2"
BR_DIR="${SCRIPT_DIR}/results/patrick/pipeline2/MGS/bracken"
OUT_DIR="${SCRIPT_DIR}/results/patrick/pipeline2/MGS"

K2_DB="/DCEG/Projects/Microbiome/Metagenomics/Kraken/kraken2/k2_standard_20240112"
BRACKEN="/DCEG/Projects/Microbiome/Metagenomics/Kraken/Bracken/bracken"

cd "${SCRIPT_DIR}"
mkdir -p "${BR_DIR}"

echo "=== Pipeline 2 — MGS Step 2: Bracken genus-level estimation (Patrick) ==="
echo ""

# Build sample name list from CSV
declare -a SAMPLE_NAMES
while IFS=',' read -r WGS_SRR S16_SRR SAMPLE_NAME; do
    [[ -z "${WGS_SRR}" ]] && continue
    SAMPLE_NAME="${SAMPLE_NAME//$'\r'/}"
    SAMPLE_NAMES+=("${SAMPLE_NAME}")
done < "${MAPPING_CSV}"

# ── Step 1: Run Bracken ─────────────────────────────────────────────────────
echo "=== Step 1: Run Bracken for genus-level estimates ==="
for SAMPLE in "${SAMPLE_NAMES[@]}"; do
    KREPORT="${K2_DIR}/${SAMPLE}.kreport"
    if [[ ! -f "${KREPORT}" ]]; then
        echo "  WARNING: ${KREPORT} not found, skipping"
        continue
    fi

    echo "  Processing: ${SAMPLE}"
    ${BRACKEN} \
        -d "${K2_DB}" \
        -i "${KREPORT}" \
        -o "${BR_DIR}/${SAMPLE}_genus.bracken" \
        -w "${BR_DIR}/${SAMPLE}_genus.breport" \
        -r 150 \
        -l G \
        -t 1
done

echo ""

# ── Step 2: Combine Bracken outputs into genus table ─────────────────────────
echo "=== Step 2: Combining Bracken genus outputs into a single table ==="

python3 << PYEOF
import os
import csv

br_dir  = "${BR_DIR}"
out_dir = "${OUT_DIR}"
mapping_csv = "${MAPPING_CSV}"

# Read sample names from mapping
sample_names = []
with open(mapping_csv) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        parts = line.split(',')
        if len(parts) >= 3:
            sample_names.append(parts[2].strip())

genus_counts = {}  # {sample: {genus_name: count}}

for sample in sample_names:
    bracken_file = os.path.join(br_dir, f"{sample}_genus.bracken")
    if not os.path.isfile(bracken_file):
        print(f"WARNING: {bracken_file} not found, skipping")
        continue

    genus_counts[sample] = {}
    with open(bracken_file) as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            genus = row['name'].strip()
            count = int(float(row['new_est_reads']))
            if count > 0:
                genus_counts[sample][genus] = count

# Collect all genera across samples
all_genera = sorted(set(g for sample in genus_counts.values() for g in sample))

# Write combined table
out_file = os.path.join(out_dir, "otu_table_genus.tsv")
os.makedirs(out_dir, exist_ok=True)
with open(out_file, 'w') as f:
    header = ["#OTU ID"] + list(genus_counts.keys())
    f.write('\t'.join(header) + '\n')
    for genus in all_genera:
        row = [genus]
        for sample in genus_counts:
            row.append(str(genus_counts[sample].get(genus, 0)))
        f.write('\t'.join(row) + '\n')

print(f"Wrote {len(all_genera)} genera x {len(genus_counts)} samples to {out_file}")
PYEOF

echo ""
echo "=== Done ==="
echo "Output files:"
echo "  ${K2_DIR}/*.kreport             (Kraken2 reports)"
echo "  ${BR_DIR}/*_genus.bracken       (Bracken genus estimates)"
echo "  ${OUT_DIR}/otu_table_genus.tsv  (combined genus table)"
