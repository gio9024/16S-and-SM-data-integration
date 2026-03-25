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

### Pipeline 2 — 16S Refseq + Kraken2/Bracken

- **16S side:** DADA2 denoising → classify against the **NCBI 16S RefSeq** database in QIIME2.
- **Shotgun side:** Classify whole WGS reads with **Kraken2** (k-mer based taxonomic classification) followed by **Bracken** (Bayesian re-estimation of abundance) using a RefSeq-based database, run within the QIIME2 **MOSHPIT** plugin.
- **Key advantage:** Uses the comprehensive NCBI RefSeq taxonomy on both sides; Kraken2/Bracken is fast and widely adopted for WGS profiling.

### Pipeline 3 — 16S Refseq + 16S Extraction from WGS

- **16S side:** DADA2 denoising → classify against the **NCBI 16S RefSeq** database in QIIME2.
- **Shotgun side:** First extract 16S-like reads from WGS data using **SortMeRNA** or **Barrnap**, then classify the extracted reads with **Kraken2/Bracken** against a **16S RefSeq** database via MOSHPIT.
- **Key advantage:** By extracting 16S sequences from shotgun reads before classification, both methods profile the same marker gene region, reducing methodological bias in the comparison.

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
