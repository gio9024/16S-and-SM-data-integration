# Zymo Pipeline 2 — 16S vs MGS Taxonomy Comparison Report

**Generated:** 2026-04-09 16:07
**Pipeline:** RefSeq 16S V4 NB classifier (16S) / Kraken2 + Bracken with full RefSeq standard DB (MGS)

---

## 1. Overview

| Metric | 16S (DADA2 + RefSeq 16S) | MGS (Kraken2/Bracken + Full RefSeq) |
|--------|--------------------------|--------------------------------------|
| Samples | 6 | 4 |
| Total genera detected | 20 | 2,186 |
| Total read counts | 241,325 | 220,779,260 |

### Sample IDs

**16S samples:**
- `NP0440-MB5_1`
- `NP0440-MB5_2`
- `NP0553-MB1_1`
- `NP0553-MB1_2`
- `NP0610-MB1_1`
- `NP0610-MB1_2`

**MGS samples:**
- `SC718268_CCGGAATT-ACCGAATG_L001` (NP0084-HE41)
- `SC718268_TGGATCAC-GCATTGGT_L001` (NP0084-HE41)
- `SC718268_CAACCTAG-AGGTCTGT_L001` (NP0084-HE42)
- `SC718268_TCTAACGC-CGCCTTAT_L001` (NP0084-HE42)

---

## 2. Genus-Level Overlap

| Category | Count |
|----------|-------|
| Shared genera (both methods) | 16 |
| Unique to 16S | 4 |
| Unique to MGS | 2,170 |
| Total unique genera | 2,190 |

---

## 3. Top 20 Genera by Total Counts

### 16S (DADA2 + RefSeq 16S V4 Classifier)

| Rank | Genus | Total Counts | Mean Rel. Abundance (%) | Also in MGS? |
|------|-------|-------------|------------------------|--------------|
| 1 | Staphylococcus | 47,867 | 19.82 | ✅ |
| 2 | Bacillus | 44,188 | 18.27 | ✅ |
| 3 | Listeria | 38,023 | 15.77 | ✅ |
| 4 | k__Bacteria;p__Proteobacteria;...;f__Enterobacteriaceae;__ | 28,014 | 11.63 | ❌ |
| 5 | Escherichia | 26,151 | 10.84 | ✅ |
| 6 | Enterococcus | 21,609 | 8.92 | ✅ |
| 7 | Lactobacillus | 21,591 | 9.01 | ✅ |
| 8 | Pseudomonas | 13,327 | 5.53 | ✅ |
| 9 | Streptococcus | 168 | 0.07 | ✅ |
| 10 | Prevotella | 107 | 0.04 | ✅ |
| 11 | Veillonella | 107 | 0.04 | ✅ |
| 12 | Haemophilus | 44 | 0.02 | ✅ |
| 13 | Gemella | 44 | 0.02 | ✅ |
| 14 | k__Bacteria;__;__;__;__;__ | 37 | 0.02 | ❌ |
| 15 | Bacteroides | 18 | 0.01 | ✅ |
| 16 | Rothia | 8 | 0.00 | ✅ |
| 17 | Neisseria | 8 | 0.00 | ✅ |
| 18 | Gemmiger | 6 | 0.00 | ❌ |
| 19 | Dorea | 4 | 0.00 | ✅ |
| 20 | unclassified Lachnospiraceae | 4 | 0.00 | ❌ |

### MGS (Kraken2/Bracken + Full RefSeq)

| Rank | Genus | Total Counts | Mean Rel. Abundance (%) | Also in 16S? |
|------|-------|-------------|------------------------|--------------|
| 1 | Pseudomonas | 38,745,901 | 17.56 | ✅ |
| 2 | Salmonella | 36,913,898 | 16.72 | ❌ |
| 3 | Bacillus | 28,084,308 | 12.72 | ✅ |
| 4 | Escherichia | 26,026,205 | 11.79 | ✅ |
| 5 | Staphylococcus | 23,423,952 | 10.61 | ✅ |
| 6 | Listeria | 22,796,061 | 10.32 | ✅ |
| 7 | Enterococcus | 22,474,021 | 10.18 | ✅ |
| 8 | Limosilactobacillus | 20,298,677 | 9.19 | ❌ |
| 9 | Shigella | 782,334 | 0.35 | ❌ |
| 10 | Homo | 572,183 | 0.26 | ❌ |
| 11 | Citrobacter | 109,689 | 0.05 | ❌ |
| 12 | Klebsiella | 90,718 | 0.04 | ❌ |
| 13 | Enterobacter | 87,846 | 0.04 | ❌ |
| 14 | Burkholderia | 29,441 | 0.01 | ❌ |
| 15 | Actinomyces | 25,127 | 0.01 | ❌ |
| 16 | Kosakonia | 16,125 | 0.01 | ❌ |
| 17 | Leclercia | 12,402 | 0.01 | ❌ |
| 18 | Campylobacter | 9,501 | 0.00 | ❌ |
| 19 | Kluyvera | 8,961 | 0.00 | ❌ |
| 20 | Cronobacter | 8,807 | 0.00 | ❌ |

---

## 4. Shared Genera — Mean Relative Abundance Comparison

Top shared genera ranked by average relative abundance across both methods:

| Genus | 16S Mean RA (%) | MGS Mean RA (%) | Ratio (MGS/16S) |
|-------|----------------|----------------|-----------------|
| Staphylococcus | 19.82 | 10.61 | 0.54 |
| Bacillus | 18.27 | 12.72 | 0.70 |
| Pseudomonas | 5.53 | 17.56 | 3.18 |
| Listeria | 15.77 | 10.32 | 0.65 |
| Escherichia | 10.84 | 11.79 | 1.09 |
| Enterococcus | 8.92 | 10.18 | 1.14 |
| Lactobacillus | 9.01 | 0.00 | 0.00 |
| Streptococcus | 0.07 | 0.00 | 0.04 |
| Veillonella | 0.04 | 0.00 | 0.01 |
| Prevotella | 0.04 | 0.00 | 0.00 |
| Haemophilus | 0.02 | 0.00 | 0.01 |
| Gemella | 0.02 | 0.00 | 0.01 |
| Bacteroides | 0.01 | 0.00 | 0.04 |
| Neisseria | 0.00 | 0.00 | 0.03 |
| Rothia | 0.00 | 0.00 | 0.03 |
| Dorea | 0.00 | 0.00 | 0.00 |

---

## 5. Genera Unique to One Method

### Unique to 16S (top 15 by mean RA)

| Genus | Mean Rel. Abundance (%) |
|-------|------------------------|
| k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Enterobacterales;f__Enterobacteriaceae;__ | 11.63 |
| k__Bacteria;__;__;__;__;__ | 0.02 |
| Gemmiger | 0.00 |
| unclassified Lachnospiraceae | 0.00 |

### Unique to MGS (top 15 by mean RA)

| Genus | Mean Rel. Abundance (%) |
|-------|------------------------|
| Salmonella | 16.72 |
| Limosilactobacillus | 9.19 |
| Shigella | 0.35 |
| Homo | 0.26 |
| Citrobacter | 0.05 |
| Klebsiella | 0.04 |
| Enterobacter | 0.04 |
| Burkholderia | 0.01 |
| Actinomyces | 0.01 |
| Kosakonia | 0.01 |
| Leclercia | 0.01 |
| Campylobacter | 0.00 |
| Kluyvera | 0.00 |
| Cronobacter | 0.00 |
| Vibrio | 0.00 |

---

## 6. Zymo Community Standard — Expected Genera Check

The Zymo mock community contains 8 known bacterial genera. Below is a comparison of how each method detects them:

| Expected Genus | 16S RA (%) | MGS RA (%) | 16S Genus Label | MGS Genus Label |
|---------------|-----------|-----------|-----------------|-----------------|
| Bacillus | 18.27 | 12.72 | Bacillus | Bacillus |
| Enterococcus | 8.92 | 10.18 | Enterococcus | Enterococcus |
| Escherichia | 10.84 | 11.79 | Escherichia | Escherichia |
| Lactobacillus | 9.01 | 0.00* | Lactobacillus | Limosilactobacillus (9.19%) |
| Listeria | 15.77 | 10.32 | Listeria | Listeria |
| Pseudomonas | 5.53 | 17.56 | Pseudomonas | Pseudomonas |
| Salmonella | 0.00 | 16.72 | ❌ Not detected | Salmonella |
| Staphylococcus | 19.82 | 10.61 | Staphylococcus | Staphylococcus |

> **\*Lactobacillus reclassification note:** The 16S RefSeq classifier assigns reads to the traditional `Lactobacillus` genus, while Kraken2 (using updated NCBI taxonomy) assigns them to `Limosilactobacillus` — a 2020 reclassification of *Lactobacillus reuteri*. Despite the different names, both represent the same organism. See [Zheng et al. 2020](https://doi.org/10.1099/ijsem.0.004107).

> **Salmonella/Enterobacteriaceae note:** The 16S side detects a large unresolved `Enterobacteriaceae` fraction (11.63%) that likely contains Salmonella reads. The V4 region of 16S rRNA cannot reliably distinguish *Salmonella* from *Escherichia* and other Enterobacteriaceae, whereas Kraken2 classifies against full genomes and resolves them.

---

## 7. Summary & Key Observations

- **16S** detected **20** genera across **6** samples (DADA2 + RefSeq 16S V4 NB classifier)
- **MGS** detected **2,186** genera across **4** samples (Kraken2/Bracken + full RefSeq standard DB)
- **16** genera were shared between both methods (16/2,190 = 0.7% of total)
- **6/8 Zymo expected genera** are directly shared with matching names
- **Lactobacillus** appears in 16S as `Lactobacillus` (9.01%) but in MGS as `Limosilactobacillus` (9.19%) due to NCBI taxonomy reclassification
- **Salmonella** is only detected by MGS (16.72%); on the 16S side, these reads fall into an unresolved `Enterobacteriaceae` group (11.63%)
- **Pseudomonas** is notably higher in MGS (17.56%) than 16S (5.53%), possibly due to multi-copy genomic sequences inflating Kraken2 estimates
- **Homo** reads (0.26%) in MGS represent host contamination classified by Kraken2 but not detectable by 16S

> **Note:** The 16S side uses the NCBI 16S RefSeq database (26,244 sequences), while the MGS side uses the full Kraken2 standard database (all RefSeq genomes). Both use NCBI taxonomy, so genus names match directly for most taxa. Key differences arise from: (1) taxonomy version differences (e.g., Lactobacillus reclassification), (2) 16S resolution limits for closely related Enterobacteriaceae, and (3) genome-wide classification detecting non-16S organisms like human reads.
