# Pipeline 3: 16S-Subset RefSeq (Extraction)

This pipeline extracts 16S rRNA reads from the shotgun pool to ensure consistency with the 16S sequencing data.

## Workflow Visualization

![Pipeline 3 Flowchart](pipeline_3_flowchart.png)

## Step-by-Step Instructions

### 1. 16S rRNA Processing (RefSeq)
- **Tool**: QIIME 2 / DADA2
- **Goal**: Standard 16S processing using RefSeq as the reference database.

### 2. Shotgun Metagenomics Processing (16S Subset)
- **Tool**: SortMeRNA / Barrnap + QIIME 2 MOSHPIT
- **Extraction**: Filter MGS FASTQ files for 16S-like reads using SortMeRNA or Barrnap.
- **Classification**: Classify ONLY the extracted 16S reads against the **RefSeq 16S** database using Kraken2/Bracken.

## References
- [SortMeRNA GitHub](https://github.com/sortmerna/sortmerna)
- [Barrnap GitHub](https://github.com/tseemann/barrnap)
- [MOSHPIT Documentation](https://bokulich-lab.github.io/moshpit-docs/chapters/03_taxonomic_classification/reads.html)
