#!/usr/bin/env bash
set -euo pipefail
##############################################################################
#  Patrick 16S V3-V4 Rerun — SLURM Submission
#
#  ROOT CAUSE: Patrick 16S uses V3-V4 primers (341F/805R, ~460bp amplicon)
#  but DADA2 was run with V4 truncation (150/150) → 0.13% merge rate.
#
#  FIX: trunc-len-f=240, trunc-len-r=200 → ~20bp overlap for V3-V4.
#
#  Submits two sequential SLURM jobs:
#    Job 1: Pipeline 1 (DADA2 + GG2 classifier)
#    Job 2: Pipeline 3 (RefSeq classifier on same ASVs) — depends on Job 1
#
#  Usage:
#    bash submit_16s_patrick_v34.sh
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/results/patrick/logs"
mkdir -p "${LOG_DIR}"

THREADS=8
MEM="32g"
WALLTIME="3-00:00:00"
PARTITION="cgrq"

# ── Job 1: Pipeline 1 — DADA2 (V3-V4 corrected) + GG2 classifier ────────────
JOB1_ID=$(sbatch \
    --partition="${PARTITION}" \
    --job-name="p1_16s_v34" \
    --mem="${MEM}" \
    --cpus-per-task="${THREADS}" \
    --time="${WALLTIME}" \
    --output="${LOG_DIR}/p1_16s_v34_%j.out" \
    --error="${LOG_DIR}/p1_16s_v34_%j.err" \
    --parsable \
    <<'SBATCH_EOF'
#!/bin/bash
set -euo pipefail

echo "================================================================"
echo "  Pipeline 1 — 16S V3-V4 Rerun (DADA2 + GG2)"
echo "  Node: $(hostname)"
echo "  Date: $(date)"
echo "================================================================"

cd /DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S-and-SM-data-integration

# Load environment
source /usr/share/modules/init/bash
module load python
eval "$(conda shell.bash hook)"
conda activate qiime2-amplicon-2024.5

echo "QIIME2: $(qiime --version 2>&1 | head -1)"
echo "Snakemake: $(snakemake --version)"

# Run Pipeline 1 Snakefile
snakemake -s pipeline1_patrick_v34_Snakefile --cores 8 --printshellcmds

echo ""
echo "================================================================"
echo "  Pipeline 1 complete — checking DADA2 stats..."
echo "================================================================"

# Print DADA2 merge statistics
python3 -c "
import zipfile

qza_path = 'results/patrick/pipeline1/16S_v34/dada2_stats.qza'
with zipfile.ZipFile(qza_path) as z:
    for name in z.namelist():
        if name.endswith('stats.tsv'):
            with z.open(name) as f:
                content = f.read().decode()
                lines = content.strip().split('\n')
                total_input = total_filtered = total_merged = total_nonchim = 0
                n_zero = n_samples = 0
                for line in lines[2:]:
                    parts = line.split('\t')
                    if len(parts) >= 9:
                        n_samples += 1
                        total_input += int(parts[1])
                        total_filtered += int(parts[2])
                        total_merged += int(parts[5])
                        total_nonchim += int(parts[7])
                        if int(parts[5]) == 0: n_zero += 1
                print(f'Samples:          {n_samples}')
                print(f'Input reads:      {total_input:>12,}')
                print(f'Filtered reads:   {total_filtered:>12,} ({total_filtered/total_input*100:.1f}%)')
                print(f'Merged reads:     {total_merged:>12,} ({total_merged/total_input*100:.1f}%)')
                print(f'Non-chimeric:     {total_nonchim:>12,} ({total_nonchim/total_input*100:.1f}%)')
                print(f'Merge rate:       {total_merged/total_filtered*100:.1f}%')
                print(f'Zero-merge:       {n_zero}/{n_samples}')
                print(f'OLD merge rate:   0.13%  |  OLD non-chimeric: 14,882')
                print(f'NEW merge rate:   {total_merged/total_filtered*100:.1f}%  |  NEW non-chimeric: {total_nonchim:,}')
"

echo ""
echo "Pipeline 1 outputs:"
ls -lh results/patrick/pipeline1/16S_v34/*.qza results/patrick/pipeline1/16S_v34/*.tsv 2>/dev/null
echo "Done at $(date)"
SBATCH_EOF
)

echo "Submitted Pipeline 1 job: ${JOB1_ID}"

# ── Job 2: Pipeline 3 — RefSeq classifier (depends on Job 1) ────────────────
JOB2_ID=$(sbatch \
    --partition="${PARTITION}" \
    --job-name="p3_16s_v34" \
    --mem="${MEM}" \
    --cpus-per-task="${THREADS}" \
    --time="2:00:00" \
    --output="${LOG_DIR}/p3_16s_v34_%j.out" \
    --error="${LOG_DIR}/p3_16s_v34_%j.err" \
    --dependency="afterok:${JOB1_ID}" \
    --parsable \
    <<'SBATCH_EOF'
#!/bin/bash
set -euo pipefail

echo "================================================================"
echo "  Pipeline 3 — 16S V3-V4 Rerun (RefSeq classifier)"
echo "  Node: $(hostname)"
echo "  Date: $(date)"
echo "================================================================"

cd /DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S-and-SM-data-integration

# Load environment
source /usr/share/modules/init/bash
module load python
eval "$(conda shell.bash hook)"
conda activate qiime2-amplicon-2024.5

echo "QIIME2: $(qiime --version 2>&1 | head -1)"

# Run Pipeline 3 Snakefile
snakemake -s pipeline3_patrick_v34_Snakefile --cores 8 --printshellcmds

echo ""
echo "Pipeline 3 outputs:"
ls -lh results/patrick/pipeline3/16S_v34/*.qza results/patrick/pipeline3/16S_v34/*.tsv 2>/dev/null

echo ""
echo "================================================================"
echo "  ALL 16S V3-V4 RERUN COMPLETE"
echo "  P1 genus table: results/patrick/pipeline1/16S_v34/otu_table_genus.tsv"
echo "  P3 genus table: results/patrick/pipeline3/16S_v34/otu_table_genus.tsv"
echo "  Original (bad) results preserved in 16S/ directories"
echo "================================================================"
echo "Done at $(date)"
SBATCH_EOF
)

echo "Submitted Pipeline 3 job: ${JOB2_ID} (depends on ${JOB1_ID})"

echo ""
echo "================================================================"
echo "  Two SLURM jobs submitted:"
echo "    Job ${JOB1_ID}: Pipeline 1 (DADA2 + GG2)  — runs first"
echo "    Job ${JOB2_ID}: Pipeline 3 (RefSeq)        — runs after Job 1"
echo ""
echo "  Monitor: squeue -u \$USER"
echo "  Logs:    ${LOG_DIR}/p1_16s_v34_${JOB1_ID}.out"
echo "           ${LOG_DIR}/p3_16s_v34_${JOB2_ID}.out"
echo "================================================================"
