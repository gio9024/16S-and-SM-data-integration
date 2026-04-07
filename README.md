# 16S and Shotgun Metagenomics Data Integration

This repository organizes a unified framework to compare **16S amplicon** and **shotgun metagenomics (SM/WGS)** profiles using a harmonized taxonomy strategy, with emphasis on reproducible cross-method concordance analysis.

## Project Goals

1. Using three pipelines to generate output for 16S and MGS results.
2. Process three pipelines on different projects:
   - a. Fecal QC data set
   - b. Internal QC data set

## Pipeline Comparison

| Pipeline | 16S rRNA gene | | | Shotgun metagenomics | | |
|----------|---------------|------|-----------|----------------------|------|-----------|
| | **Database** | **Tool** | **Resources** | **Database** | **Tool** | **Resources** |
| 1 | Greengenes2 | DADA2 | [Introducing Greengenes2](https://forum.qiime2.org/t/introducing-greengenes2-2022-10/25291), [biocore/q2-greengenes2](https://github.com/biocore/q2-greengenes2) | Greengenes2 | Woltka | [Introducing Greengenes2](https://forum.qiime2.org/t/introducing-greengenes2-2022-10/25291) |
| 2 | 16S Refseq | DADA2 | | Refseq | Kraken2/Bracken (in MOSHPIT) | [sortmerna](https://github.com/sortmerna/sortmerna), [barrnap](https://github.com/tseemann/barrnap), [MOSHPIT docs](https://bokulich-lab.github.io/moshpit-docs/chapters/03_taxonomic_classification/reads.html) |
| 3 | 16S Refseq | DADA2 | | 16S Refseq | SortMeRNA or Barrnap (Extract 16S), Kraken2/Bracken (in MOSHPIT) | [sortmerna](https://github.com/sortmerna/sortmerna), [barrnap](https://github.com/tseemann/barrnap), [MOSHPIT docs](https://bokulich-lab.github.io/moshpit-docs/chapters/03_taxonomic_classification/reads.html) |

### Pipeline 1 — Greengenes2 + Woltka

- **16S side:** DADA2 denoising → classify against the **Greengenes2** (2024.09) database using a pre-trained Naive Bayes backbone classifier in QIIME2.
- **Shotgun side:** Map WGS reads to Greengenes2 reference genomes using **Woltka** (Web of Life Toolkit App), which produces OGU (Operational Genomic Unit) feature tables directly compatible with the same GG2 taxonomy.
- **Key advantage:** Both sides share the exact same Greengenes2 taxonomy tree, enabling direct label-level comparison without additional harmonization.

**How to Run Pipeline 1:**

**A. 16S portion** (Snakemake — runs on interactive node)

1. Navigate to the project directory:
   ```bash
   cd /DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S-and-SM-data-integration
   ```
2. Start an interactive session and activate your QIIME2 environment:
   ```bash
   sinteractive --mem=32g -c16
   conda activate qiime2-amplicon-2024.5
   ```
3. Run the 16S pipeline:
   ```bash
   module load python
   snakemake -s pipeline1_Snakefile --cores 8
   ```
4. Output files in `results/16S/`:
   - `demux.qza` — imported paired-end reads
   - `dada2_table.qza` — ASV feature table
   - `rep_seqs.qza` — representative sequences
   - `dada2_stats.qza` — denoising statistics
   - `gg2_taxonomy.qza` — GG2 taxonomy assignments (Naive Bayes classifier, v2024.09)

**B. MGS portion** (standalone scripts — submitted via SLURM sbatch)

> Requires ≥80 GB memory per alignment job. Do **not** run on an interactive node.

1. **Step 1 — Bowtie2 alignment:** Submit individual sbatch jobs to SLURM.
   ```bash
   cd /DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S-and-SM-data-integration
   bash submit_bowtie2_zymo.sh
   # Submits 4 jobs (2 samples × 2 FASTQ pairs), each with 80 GB / 4 CPUs / 3-day walltime
   # Monitor with: squeue -u $USER
   ```
2. **Step 2 — Woltka + QIIME2 processing:** Run after *all* Bowtie2 jobs finish.
   ```bash
   # Activate environments (need both woltka and qiime2)
   conda activate qiime2-amplicon-2024.5
   bash process_woltka_zymo.sh
   ```
3. Output files in `results/MGS/`:
   - `alignments/*.sam` — Bowtie2 alignments against WoLr2
   - `woltka_out.biom` — raw OGU feature table
   - `ogu_table.qza` — OGU table (QIIME2 artifact)
   - `ogu_taxonomy.qza` — GG2 taxonomy for OGUs
   - `ogu_table_gg2.qza` — OGU table filtered to GG2 features
   - `otu_table_genus.tsv` — genus-level counts (samples × genus)
   - `otu_table_full.tsv` — full OGU counts with GG2 taxonomy column

### Pipeline 2 — 16S Refseq + Kraken2/Bracken

- **16S side:** DADA2 denoising → classify against the **NCBI 16S RefSeq** database in QIIME2.
- **Shotgun side:** Classify whole WGS reads with **Kraken2** (k-mer based taxonomic classification) followed by **Bracken** (Bayesian re-estimation of abundance) using a RefSeq-based database, run within the QIIME2 **MOSHPIT** plugin.
- **Key advantage:** Uses the comprehensive NCBI RefSeq taxonomy on both sides; Kraken2/Bracken is fast and widely adopted for WGS profiling.

### Pipeline 3 — 16S Refseq + 16S Extraction from WGS

- **16S side:** DADA2 denoising → classify against the **NCBI 16S RefSeq** database using the V4 NB classifier in QIIME2.
- **Shotgun side:** Extract 16S rRNA reads from WGS data using **SortMeRNA** (v4.3.6, SILVA rRNA database), then import extracted reads into QIIME2, run DADA2 denoising, and classify ASVs with the **same RefSeq 16S NB classifier** (full-length version).
- **Key advantage:** Both sides use the **exact same RefSeq 16S database and NCBI taxonomy**, ensuring genus labels are directly comparable. By extracting 16S sequences from shotgun reads before classification, both methods profile the same marker gene region, reducing methodological bias.

**How to Run Pipeline 3:**

**A. One-time setup** — install SortMeRNA

```bash
# Create sortmerna conda environment (v4.3.6 for compute node compatibility)
conda create -n sortmerna -c bioconda -c conda-forge sortmerna=4.3.6 python=3.10 -y

# Download SortMeRNA rRNA reference database
cd /DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S-and-SM-data-integration
mkdir -p databases/sortmerna_rRNA
cd databases/sortmerna_rRNA
wget https://github.com/biocore/sortmerna/releases/download/v4.3.4/database.tar.gz
tar -xzf database.tar.gz
cd ../..
```

**B. 16S portion** (Snakemake — runs on interactive node)

> Reuses DADA2 outputs (`dada2_table.qza`, `rep_seqs.qza`) from Pipeline 1.

1. Start an interactive session and activate QIIME2:
   ```bash
   sinteractive --mem=32g -c16
   conda activate qiime2-amplicon-2024.5
   ```
2. Run the 16S pipeline:
   ```bash
   module load python
   snakemake -s pipeline3_Snakefile -c8
   ```
3. Output files in `results/pipeline3/16S/`:
   - `refseq_taxonomy.qza` — RefSeq 16S taxonomy assignments (V4 NB classifier)
   - `table_genus.qza` — genus-level collapsed table
   - `otu_table_genus.tsv` — genus-level counts (samples × genus, NCBI taxonomy)

**C. MGS portion — Step 1: Extract 16S reads** (SLURM sbatch)

> Requires 32 GB memory per job. Uses SortMeRNA to identify and extract 16S rRNA reads from shotgun FASTQs.

1. Submit SortMeRNA extraction jobs:
   ```bash
   cd /DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S-and-SM-data-integration
   bash submit_sortmerna_zymo.sh
   # Submits 4 jobs (2 samples × 2 FASTQ pairs), each with 32 GB / 8 CPUs / 1-day walltime
   # Monitor with: squeue -u $USER
   ```
2. Output files in `results/pipeline3/MGS/sortmerna/`:
   - `{prefix}_16S_fwd.fastq.gz` — extracted 16S forward reads
   - `{prefix}_16S_rev.fastq.gz` — extracted 16S reverse reads
   - `{prefix}_non16S_fwd/rev.fastq.gz` — non-16S reads (discarded)

**D. MGS portion — Step 2: QIIME2 classification** (interactive node, after SortMeRNA finishes)

> Imports extracted 16S reads into QIIME2 and classifies with the **same RefSeq 16S database** used on the 16S amplicon side.

1. Activate QIIME2 and run the processing script:
   ```bash
   conda activate qiime2-amplicon-2024.5
   bash process_sortmerna_qiime2_zymo.sh
   ```
2. Output files in `results/pipeline3/MGS/`:
   - `16S_extracted_demux.qza` — imported extracted 16S reads
   - `dada2_table.qza` — ASV feature table from extracted 16S reads
   - `rep_seqs.qza` — representative sequences
   - `refseq_taxonomy.qza` — RefSeq 16S taxonomy (full-length NB classifier)
   - `table_genus.qza` — genus-level collapsed table
   - `otu_table_genus.tsv` — genus-level counts (samples × genus, NCBI taxonomy)

**E. Comparison**

Both genus tables use NCBI taxonomy labels (`k__Bacteria; p__...; g__...`):
- `results/pipeline3/16S/otu_table_genus.tsv` — 16S amplicon side
- `results/pipeline3/MGS/otu_table_genus.tsv` — MGS extracted-16S side

> **Note:** The 16S side uses the V4 region NB classifier (`refseq16s_V4_nb.qza`) while the MGS side uses the full-length NB classifier (`refseq16s_fullLength_nb.qza`). Both are trained on the same underlying RefSeq 16S sequences (26,244 dereplicated sequences) with identical NCBI taxonomy, so genus labels match exactly.

## Database Overview

| Database | Version | Description | Used In |
|----------|---------|-------------|---------|
| **Greengenes2** | 2024.09 | Unified phylogenomic reference integrating full-length 16S sequences with whole-genome data. Provides a single taxonomy tree usable by both 16S classifiers and WGS tools like Woltka. | Pipeline 1 (16S + Shotgun) |
| **NCBI RefSeq** (full) | Latest | Comprehensive collection of curated genomic sequences from NCBI. Used as the Kraken2/Bracken index for whole-genome shotgun classification. | Pipeline 2 (Shotgun) |
| **NCBI 16S RefSeq** | Latest | Curated subset of NCBI RefSeq containing only 16S rRNA gene sequences. Used for both 16S amplicon classification in QIIME2 and for classifying 16S reads extracted from WGS. | Pipeline 2 & 3 (16S); Pipeline 3 (Shotgun) |

### Key Database Considerations

- **Taxonomy consistency:** Pipeline 1 has built-in consistency since both sides use the same Greengenes2 tree. Pipelines 2 and 3 rely on NCBI taxonomy, which is shared across RefSeq products but may differ from GG2 labels at certain ranks.
- **Database scope:** Full RefSeq (Pipeline 2 shotgun) covers all genomic regions, while 16S RefSeq (Pipeline 3 shotgun) is restricted to the 16S marker gene — this is intentional to match the amplicon approach.
- **Version pinning:** Record exact database build dates/versions for each run to ensure reproducibility.
