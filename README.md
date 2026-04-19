# 16S and Shotgun Metagenomics Data Integration

This repository organizes a unified framework to compare **16S amplicon** and **shotgun metagenomics (SM/WGS)** profiles using a harmonized taxonomy strategy, with emphasis on reproducible cross-method concordance analysis.

## Project Goals

1. Using three pipelines to generate output for 16S and MGS results.
2. Process three pipelines on different datasets:
   - a. **Zymo mock community** — benchmark dataset (completed)
   - b. **Patrick SRA dataset** — 107 paired 16S + WGS samples (in progress)
   - c. Fecal QC dataset (planned)

---

## Datasets

### Zymo Mock Community (Benchmark)

| Field | Details |
|---|---|
| **Purpose** | Benchmarking — known-composition mock community (ZymoBIOMICS) |
| **Samples** | 2 WGS + 2 16S paired samples |
| **Sample names** | Zymo-1, Zymo-2 |
| **Status** | ✅ All three pipelines completed |
| **Data location** | `DataSets/Zymo/` |
| **Scripts** | `submit_bowtie2_zymo.sh`, `submit_kraken2_p2_zymo.sh`, `submit_sortmerna_zymo.sh`, etc. |
| **Results** | `results/zymo/pipeline1-3/` |
| **Reports** | `Zymo_Pipeline1_Comparison_Report.md`, `Zymo_Pipeline2_Comparison_Report.md`, `Zymo_Pipeline3_Comparison_Report.md`, `Zymo_Combine_Report.md` |

### Patrick SRA Dataset

| Field | Details |
|---|---|
| **Source** | NCBI SRA (Patrick et al.) |
| **Samples** | 107 paired samples — each with matched 16S amplicon + WGS |
| **Sample naming** | `BCH-F*` (fecal) and `BCH-h*` series |
| **Sample mapping** | `DataSets/Patrick_SRA_Data/16S_WGS_sample_name_mappings.csv` |
| **Mapping format** | `WGS_SRR, 16S_SRR, SAMPLE_NAME` (no header, comma-separated) |
| **Data location** | `DataSets/Patrick_SRA_Data/WGS_RAW/` and `DataSets/Patrick_SRA_Data/16S_RAW/` |
| **Scripts** | See table below |
| **Results** | `results/patrick/pipeline1-3/` |
| **Processing guide** | [`processing_new_dataset.md`](processing_new_dataset.md) |

**Patrick processing scripts:**

| Pipeline | Step | Script |
|---|---|---|
| P1 MGS | Bowtie2 alignment | `submit_bowtie2_patrick.sh` |
| P1 MGS | Woltka + QIIME2 export (parallel) | `submit_woltka_patrick.sh` |
| P1 16S | DADA2 + GG2 classify | `pipeline1_patrick_Snakefile` |
| P2 MGS | Kraken2 classification | `submit_kraken2_p2_patrick.sh` |
| P2 MGS | Bracken + combine table | `process_bracken_p2_patrick.sh` |
| P3 MGS | SortMeRNA 16S extraction | `submit_sortmerna_patrick.sh` |
| P3 MGS | Kraken2 on extracted 16S | `submit_kraken2_p3_patrick.sh` |
| P3 MGS | Bracken + combine table | `process_bracken_p3_patrick.sh` |
| P2 & P3 16S | RefSeq 16S classify (shared) | `pipeline3_patrick_Snakefile` |

**Current processing status (as of 2026-04-19):**

| Step | Status |
|---|---|
| P1 MGS: Bowtie2 (107 SAM files) | ✅ Complete |
| P1 MGS: Woltka parallel batches | 🔄 Running (10 batch jobs + merge pending) |
| P1 16S: DADA2 + GG2 | ⏳ Pending |
| P2 MGS: Kraken2 (107 kreports) | ✅ Complete |
| P2 MGS: Bracken + genus table | ⏳ Pending |
| P3 MGS: SortMeRNA (107 extractions) | ✅ Complete |
| P3 MGS: Kraken2 on extracted 16S | ⏳ Pending (submit next) |
| P3 MGS: Bracken + genus table | ⏳ Pending |
| P2 & P3 16S: RefSeq classify | ⏳ Pending (after P1 16S) |

---

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

- **16S side:** DADA2 denoising → classify against the **NCBI 16S RefSeq** database using the V4 NB classifier in QIIME2. (Same as Pipeline 3 16S side.)
- **Shotgun side:** Classify whole WGS reads with **Kraken2** (k-mer based taxonomic classification) against the full Kraken2 standard database (built from RefSeq genomes), followed by **Bracken** (Bayesian re-estimation of abundance at genus level).
- **Key advantage:** Uses the comprehensive NCBI RefSeq taxonomy on both sides; Kraken2/Bracken is fast and widely adopted for WGS profiling.

> **Note on taxonomy:** Both sides use NCBI taxonomy, so genus names match directly (e.g., "Bacillus"). However, the 16S side classifies against 16S rRNA sequences only, while the MGS side classifies against full genomes — abundance profiles may differ due to this methodological difference.

**How to Run Pipeline 2:**

**A. 16S portion** — Already done

> Reuses the same results from Pipeline 3's 16S side (`results/pipeline3/16S/otu_table_genus.tsv`), which classifies DADA2 ASVs against the RefSeq 16S V4 NB classifier.

**B. MGS portion — Step 1: Kraken2 classification** (SLURM sbatch)

> Classifies raw shotgun reads against the full Kraken2 standard database. Requires ≥100 GB memory (the hash table alone is 72 GB).

1. Submit Kraken2 classification jobs:
    ```bash
    cd /DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S-and-SM-data-integration
    bash submit_kraken2_p2_zymo.sh
    # Submits 4 jobs (2 samples × 2 FASTQ pairs), each with 100 GB / 8 CPUs / 1-day walltime
    # Monitor with: squeue -u $USER
    ```
2. Output files in `results/pipeline2/MGS/kraken2/`:
    - `{prefix}.kraken` — per-read classification
    - `{prefix}.kreport` — Kraken2 summary report

**C. MGS portion — Step 2: Bracken genus estimation** (interactive, after Kraken2 finishes)

> Runs Bracken for genus-level abundance re-estimation and combines all libraries into a single table.

1. Run Bracken processing:
    ```bash
    module load kraken/2.17.1
    bash process_bracken_p2_zymo.sh
    ```
2. Output files in `results/pipeline2/MGS/`:
    - `bracken/{prefix}_genus.bracken` — per-library Bracken genus estimates
    - `bracken/{prefix}_genus.breport` — Bracken-adjusted Kraken reports
    - `otu_table_genus.tsv` — combined genus-level counts (samples × genus)

**D. Comparison**

Both genus tables use NCBI taxonomy labels:
- `results/pipeline3/16S/otu_table_genus.tsv` — 16S amplicon side (RefSeq 16S V4 classifier)
- `results/pipeline2/MGS/otu_table_genus.tsv` — MGS side (Kraken2/Bracken, full RefSeq)

### Pipeline 3 — 16S Refseq + 16S Extraction from WGS

- **16S side:** DADA2 denoising → classify against the **NCBI 16S RefSeq** database using the V4 NB classifier in QIIME2. (Same as Pipeline 2 16S side.)
- **Shotgun side:** Extract 16S rRNA reads from WGS data using **SortMeRNA** (v4.3.6, SILVA rRNA database), then classify extracted reads with **Kraken2/Bracken** using the same Kraken2 standard database as Pipeline 2.
- **Key advantage:** By extracting 16S sequences from shotgun reads before classification, Pipeline 3 isolates the taxonomic signal from the same marker gene region as the 16S amplicon data. Comparing Pipeline 2 (all reads) vs Pipeline 3 (16S reads only) reveals how much non-16S genomic content influences Kraken2 classification.

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
   - `{prefix}_16S_fwd.fq.gz` — extracted 16S forward reads
   - `{prefix}_16S_rev.fq.gz` — extracted 16S reverse reads
   - `{prefix}_non16S_fwd/rev.fq.gz` — non-16S reads (discarded)

**D. MGS portion — Step 2: Kraken2 classification** (SLURM sbatch, after SortMeRNA finishes)

> Classifies extracted 16S reads against the Kraken2 standard database (same as Pipeline 2). Requires ≥100 GB memory for the database.

1. Submit Kraken2 classification jobs:
    ```bash
    cd /DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S-and-SM-data-integration
    bash submit_kraken2_p3_zymo.sh
    # Submits 4 jobs (cgrq partition, 100 GB / 8 CPUs / 1-day walltime)
    # Monitor with: squeue -u $USER
    ```
2. Output files in `results/pipeline3/MGS/kraken2/`:
    - `{prefix}.kraken` — per-read classification
    - `{prefix}.kreport` — Kraken2 summary report

**E. MGS portion — Step 3: Bracken genus estimation** (interactive, after Kraken2 finishes)

> Runs Bracken for genus-level abundance re-estimation and combines all libraries into a single table.

1. Run Bracken processing:
    ```bash
    module load kraken/2.17.1
    bash process_bracken_p3_zymo.sh
    ```
2. Output files in `results/pipeline3/MGS/`:
    - `bracken/{prefix}_genus.bracken` — per-library Bracken genus estimates
    - `bracken/{prefix}_genus.breport` — Bracken-adjusted Kraken reports
    - `otu_table_genus.tsv` — combined genus-level counts (samples × genus)

**F. Comparison**

Both genus tables use NCBI taxonomy labels:
- `results/pipeline3/16S/otu_table_genus.tsv` — 16S amplicon side (RefSeq 16S V4 classifier)
- `results/pipeline3/MGS/otu_table_genus.tsv` — MGS side (Kraken2/Bracken on extracted 16S reads)

> **Pipeline 2 vs 3 (MGS side):** Both use the same Kraken2 standard database, but Pipeline 2 classifies **all** shotgun reads while Pipeline 3 classifies only **SortMeRNA-extracted 16S** reads. This reveals whether pre-filtering to 16S sequences changes the taxonomic profile.

## Database Overview

| Database | Version | Description | Used In |
|----------|---------|-------------|---------|
| **Greengenes2** | 2024.09 | Unified phylogenomic reference integrating full-length 16S sequences with whole-genome data. Provides a single taxonomy tree usable by both 16S classifiers and WGS tools like Woltka. | Pipeline 1 (16S + Shotgun) |
| **NCBI RefSeq** (full) | 2024-01-12 | Comprehensive collection of curated genomic sequences from NCBI. Used as the Kraken2/Bracken index for whole-genome shotgun classification. | Pipeline 2 (Shotgun) |
| **NCBI 16S RefSeq** | Nov 2024 | Curated subset of NCBI RefSeq containing only 16S rRNA gene sequences (26,244 dereplicated). Used for 16S amplicon classification in QIIME2 and for classifying 16S reads extracted from WGS. | Pipeline 2 & 3 (16S); Pipeline 3 (Shotgun) |
| **SortMeRNA rRNA** | v4.3 | SILVA-based rRNA reference database shipped with SortMeRNA. Used to extract 16S reads from shotgun data. | Pipeline 3 (Shotgun) |

### Database Locations on Cluster

**Pipeline 1 — Greengenes2:**
| File | Path |
|------|------|
| GG2 V4 NB Classifier | `/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S/2024.09.backbone.v4.nb.qza` |
| GG2 Taxonomy QZA | `/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/greengenes2-2024.09-taxonomy.qza` |
| GG2 Taxonomy TSV (for Woltka) | `/DCEG/Projects/Microbiome/Combined_Study/gg2_refs/taxonomy.tsv` |
| WoLr2 Bowtie2 Index | `/DCEG/Projects/Microbiome/Combined_Study/vol2/bowtie2/WoLr2/WoLr2` |

**Pipeline 2 — Kraken2/Bracken (full RefSeq):**
| File | Path |
|------|------|
| Kraken2 Standard Database | `/DCEG/Projects/Microbiome/Metagenomics/Kraken/kraken2/k2_standard_20240112/` |
| Bracken Binary | `/DCEG/Projects/Microbiome/Metagenomics/Kraken/Bracken/bracken` |

**Pipelines 2 & 3 — NCBI 16S RefSeq:**
| File | Path |
|------|------|
| RefSeq 16S V4 NB Classifier (16S amplicon) | `/DCEG/Projects/Microbiome/Combined_Study/RefSeq-16S/refseq16s_V4_nb.qza` |
| RefSeq 16S Full-Length NB Classifier (MGS extracted 16S) | `/DCEG/Projects/Microbiome/Combined_Study/RefSeq-16S/refseq16s_fullLength_nb.qza` |
| RefSeq 16S Taxonomy | `/DCEG/Projects/Microbiome/Combined_Study/RefSeq-16S/refseq16s_taxonomy.qza` |
| RefSeq 16S Reference Sequences | `/DCEG/Projects/Microbiome/Combined_Study/RefSeq-16S/refseq16s.derep.fna` |

**Pipeline 3 — SortMeRNA:**
| File | Path |
|------|------|
| SortMeRNA rRNA Database (SILVA) | `databases/sortmerna_rRNA/smr_v4.3_default_db.fasta` |

### Key Database Considerations

- **Taxonomy consistency:** Pipeline 1 has built-in consistency since both sides use the same Greengenes2 tree. Pipelines 2 and 3 rely on NCBI taxonomy, which is shared across RefSeq products but may differ from GG2 labels at certain ranks.
- **Database scope:** Full RefSeq (Pipeline 2 shotgun) covers all genomic regions, while 16S RefSeq (Pipeline 3 shotgun) is restricted to the 16S marker gene — this is intentional to match the amplicon approach.
- **Version pinning:** Record exact database build dates/versions for each run to ensure reproducibility.
