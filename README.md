# 16S and Shotgun Metagenomics Data Integration

This repository organizes a unified framework to compare **16S amplicon** and **shotgun metagenomics (SM/WGS)** profiles using a harmonized taxonomy strategy, with emphasis on reproducible cross-method concordance analysis.

## Project Goals

1. Process 16S and shotgun data with comparable taxonomic labels.
2. Quantify agreement and disagreement between methods at genus/species level.
3. Generate interpretable summary reports for method benchmarking.
4. Transition to a GTDB-centered integration workflow for improved harmonization.

## Pipeline Comparison

| Pipeline | 16S rRNA gene | | | Shotgun metagenomics | | |
|----------|---------------|------|-----------|----------------------|------|-----------|
| | **Database** | **Tool** | **Resources** | **Database** | **Tool** | **Resources** |
| 1 | Greengenes2 | DADA2 | [Introducing Greengenes2](https://forum.qiime2.org/t/introducing-greengenes2-2022-10/25291), [biocore/q2-greengenes2](https://github.com/biocore/q2-greengenes2) | Greengenes2 | Woltka | [Introducing Greengenes2](https://forum.qiime2.org/t/introducing-greengenes2-2022-10/25291) |
| 2 | 16S Refseq | DADA2 | | Refseq | Kraken2/Bracken (in MOSHPIT) | [sortmerna](https://github.com/sortmerna/sortmerna), [barrnap](https://github.com/tseemann/barrnap), [MOSHPIT docs](https://bokulich-lab.github.io/moshpit-docs/chapters/03_taxonomic_classification/reads.html) |
| 3 | 16S Refseq | DADA2 | | 16S Refseq | SortMeRNA or Barrnap (Extract 16S), Kraken2/Bracken (in MOSHPIT) | [sortmerna](https://github.com/sortmerna/sortmerna), [barrnap](https://github.com/tseemann/barrnap), [MOSHPIT docs](https://bokulich-lab.github.io/moshpit-docs/chapters/03_taxonomic_classification/reads.html) |


