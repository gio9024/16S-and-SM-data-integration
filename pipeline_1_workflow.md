# Pipeline 1: Greengenes2 Integration

This document outlines the workflow for **Pipeline 1**, which uses **Greengenes2 (2024.09)** as the common reference taxonomy for both 16S amplicon and shotgun metagenomics data.

## Workflow Visualization

![Pipeline 1 Flowchart](pipeline_1_flowchart.png)

## Key Implementation Steps

### 16S rRNA Pipeline

1. **QIIME2 Import** — Import paired-end 16S FASTQ files via manifest into QIIME2 (`SampleData[PairedEndSequencesWithQuality]`).
2. **DADA2 Denoise** — Denoise paired reads (`qiime dada2 denoise-paired`, trunc 150/150) to produce ASV feature table and representative sequences.
3. **GG2 V4 NB Classifier** — Classify ASVs against the Greengenes2 2024.09 V4 backbone Naive Bayes classifier using `qiime feature-classifier classify-sklearn`.
4. **Collapse to Genus** — Collapse the ASV table to genus level (level 6) using `qiime taxa collapse`.
5. **Export TSV** — Export genus-level table to TSV via `biom convert`.

### MGS Shotgun Pipeline

1. **Bowtie2 Alignment** — Align shotgun reads against the **Web of Life r2 (WoLr2)** reference genomes using Bowtie2 (≥80 GB memory, submitted via SLURM sbatch).
2. **Woltka Classify** — Run Woltka OGU classification on the SAM alignments (standalone, in woltka conda env).
3. **Import BIOM to QIIME2** — Import the Woltka OGU BIOM table into QIIME2 as a `FeatureTable[Frequency]`.
4. **Import GG2 Taxonomy** — Import the GG2 taxonomy TSV as `FeatureData[Taxonomy]`.
5. **Filter to GG2 Features** — Filter the OGU table to retain only features present in the GG2 taxonomy using `qiime feature-table filter-features`.
6. **Collapse to Genus** — Collapse to genus level (level 6) using `qiime taxa collapse`.
7. **Export TSV** — Export genus-level and full OGU tables to TSV.

### Cross-Method Comparison

Both genus-level TSV files use Greengenes2 taxonomy labels, enabling direct comparison:
- `results/16S/otu_table_genus.tsv` — 16S amplicon side
- `results/MGS/otu_table_genus.tsv` — MGS shotgun side

## References
- [Greengenes2 (2024.09)](https://forum.qiime2.org/t/introducing-greengenes2-2022-10/25291)
- [q2-greengenes2 GitHub](https://github.com/biocore/q2-greengenes2)
- [Woltka](https://github.com/qiyunzhu/woltka)
