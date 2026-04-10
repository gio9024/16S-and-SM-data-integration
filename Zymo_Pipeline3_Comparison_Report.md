# Zymo Pipeline 3 — 16S vs MGS Taxonomy Comparison Report

**Generated:** 2026-04-09 21:00
**Pipeline:** RefSeq 16S V4 NB classifier (16S) / SortMeRNA extraction + Kraken2/Bracken with full RefSeq standard DB (MGS)

---

## 1. Overview

| Metric | 16S (DADA2 + RefSeq 16S) | MGS (SortMeRNA + Kraken2/Bracken) |
|--------|--------------------------|-------------------------------------|
| Samples | 6 | 4 |
| Total genera detected | 20 | 1,244 |
| Total read counts | 241,325 | 3,822,488 |

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
| Unique to MGS | 1,228 |
| Total unique genera | 1,248 |

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

### MGS (SortMeRNA + Kraken2/Bracken)

| Rank | Genus | Total Counts | Mean Rel. Abundance (%) | Also in 16S? |
|------|-------|-------------|------------------------|--------------|
| 1 | Bacillus | 725,494 | 18.95 | ✅ |
| 2 | Salmonella | 684,364 | 17.92 | ❌ |
| 3 | Staphylococcus | 450,434 | 11.79 | ✅ |
| 4 | Listeria | 419,508 | 10.96 | ✅ |
| 5 | Limosilactobacillus | 343,287 | 8.98 | ❌ |
| 6 | Escherichia | 337,880 | 8.83 | ✅ |
| 7 | Pseudomonas | 301,990 | 7.91 | ✅ |
| 8 | Enterococcus | 226,716 | 5.93 | ✅ |
| 9 | Homo | 141,309 | 3.71 | ❌ |
| 10 | Klebsiella | 36,034 | 0.94 | ❌ |
| 11 | Burkholderia | 27,606 | 0.72 | ❌ |
| 12 | Actinomyces | 15,336 | 0.40 | ❌ |
| 13 | Enterobacter | 12,268 | 0.32 | ❌ |
| 14 | Shigella | 11,777 | 0.31 | ❌ |
| 15 | Clostridioides | 11,244 | 0.30 | ❌ |
| 16 | Vibrio | 7,169 | 0.19 | ❌ |
| 17 | Streptococcus | 5,730 | 0.15 | ✅ |
| 18 | Campylobacter | 3,782 | 0.10 | ❌ |
| 19 | Stenotrophomonas | 3,573 | 0.09 | ❌ |
| 20 | Yersinia | 3,093 | 0.08 | ❌ |

---

## 4. Shared Genera — Mean Relative Abundance Comparison

Top shared genera ranked by average relative abundance across both methods:

| Genus | 16S Mean RA (%) | MGS Mean RA (%) | Ratio (MGS/16S) |
|-------|----------------|----------------|-----------------|
| Staphylococcus | 19.82 | 11.79 | 0.60 |
| Bacillus | 18.27 | 18.95 | 1.04 |
| Listeria | 15.77 | 10.96 | 0.69 |
| Escherichia | 10.84 | 8.83 | 0.82 |
| Enterococcus | 8.92 | 5.93 | 0.67 |
| Pseudomonas | 5.53 | 7.91 | 1.43 |
| Lactobacillus | 9.01 | 0.05 | 0.01 |
| Streptococcus | 0.07 | 0.15 | 2.12 |
| Veillonella | 0.04 | 0.00 | 0.00 |
| Prevotella | 0.04 | 0.00 | 0.01 |
| Haemophilus | 0.02 | 0.00 | 0.03 |
| Gemella | 0.02 | 0.00 | 0.12 |
| Bacteroides | 0.01 | 0.00 | 0.19 |
| Neisseria | 0.00 | 0.00 | 0.53 |
| Rothia | 0.00 | 0.00 | 0.04 |
| Dorea | 0.00 | 0.00 | 0.01 |

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
| Salmonella | 17.92 |
| Limosilactobacillus | 8.98 |
| Homo | 3.71 |
| Klebsiella | 0.94 |
| Burkholderia | 0.72 |
| Actinomyces | 0.40 |
| Enterobacter | 0.32 |
| Shigella | 0.31 |
| Clostridioides | 0.30 |
| Vibrio | 0.19 |
| Campylobacter | 0.10 |
| Stenotrophomonas | 0.09 |
| Yersinia | 0.08 |
| Citrobacter | 0.07 |
| Priestia | 0.05 |

---

## 6. Zymo Community Standard — Expected Genera Check

The Zymo mock community contains 8 known bacterial genera:

| Expected Genus | 16S RA (%) | MGS RA (%) | 16S Label | MGS Label |
|---------------|-----------|-----------|-----------|-----------|
| Bacillus | 18.27 | 18.95 | Bacillus | Bacillus |
| Enterococcus | 8.92 | 5.93 | Enterococcus | Enterococcus |
| Escherichia | 10.84 | 8.83 | Escherichia | Escherichia |
| Lactobacillus | 9.01 | 0.05* | Lactobacillus | Limosilactobacillus (8.98%) |
| Listeria | 15.77 | 10.96 | Listeria | Listeria |
| Pseudomonas | 5.53 | 7.91 | Pseudomonas | Pseudomonas |
| Salmonella | 0.00 | 17.92 | ❌ Not detected | Salmonella |
| Staphylococcus | 19.82 | 11.79 | Staphylococcus | Staphylococcus |

> **\*Lactobacillus:** Same issue as Pipeline 2 — the 16S classifier uses the traditional name `Lactobacillus`, while Kraken2 uses the updated NCBI name `Limosilactobacillus` (reclassification of *L. reuteri*, [Zheng et al. 2020](https://doi.org/10.1099/ijsem.0.004107)).

> **Salmonella:** Not resolved by 16S V4 region — lumped into unresolved `Enterobacteriaceae` (11.63%).

---

## 7. Pipeline 2 vs Pipeline 3 — MGS Side Comparison

Both pipelines use the same Kraken2 standard database and Bracken, but differ in input:
- **Pipeline 2:** All raw shotgun reads (220M reads total)
- **Pipeline 3:** Only SortMeRNA-extracted 16S reads (3.8M reads total, ~1.5% of raw)

| Genus | Pipeline 2 RA (%) | Pipeline 3 RA (%) | Effect of 16S Extraction |
|-------|-------------------|-------------------|-------------------------|
| Bacillus | 12.72 | 18.95 | ↑ Enriched by 16S filtering |
| Staphylococcus | 10.61 | 11.79 | ≈ Similar |
| Listeria | 10.32 | 10.96 | ≈ Similar |
| Escherichia | 11.79 | 8.83 | ↓ Reduced |
| Enterococcus | 10.18 | 5.93 | ↓ Reduced |
| Pseudomonas | 17.56 | 7.91 | ↓↓ Significantly reduced |
| Salmonella | 16.72 | 17.92 | ≈ Similar |
| Lactobacillus/Limosilactobacillus | 0.00/9.19 | 0.05/8.98 | ≈ Similar |

| Metric | Pipeline 2 | Pipeline 3 |
|--------|-----------|-----------|
| Total genera detected | 2,186 | 1,244 |
| Total classified reads | 220.8M | 3.8M |
| P3 genera ⊆ P2 genera | — | ✅ All 1,244 P3 genera found in P2 |

### Key Differences

- **Pseudomonas** drops from 17.56% (P2) to 7.91% (P3) — suggests many *Pseudomonas* reads in P2 come from non-16S genomic regions
- **Bacillus** increases from 12.72% (P2) to 18.95% (P3) — 16S filtering enriches for organisms with higher 16S copy numbers
- **Fewer genera** in P3 (1,244 vs 2,186) — extracting only 16S reads removes organisms that don't contribute 16S sequences
- **All P3 genera are a subset of P2** — no novel genera appear from 16S extraction alone

---

## 8. Summary & Key Observations

- **16S** detected **20** genera across **6** samples (DADA2 + RefSeq 16S V4 NB classifier)
- **MGS** detected **1,244** genera across **4** samples (SortMeRNA → Kraken2/Bracken on extracted 16S)
- **16** genera were shared between both methods (16/1,248 = 1.3% of total)
- **6/8 Zymo expected genera** directly shared with matching names
- **Lactobacillus** → `Limosilactobacillus` taxonomy reclassification (same organism)
- **Salmonella** only detected by MGS — 16S V4 region cannot resolve Enterobacteriaceae to genus
- **Pipeline 3 detects fewer genera than Pipeline 2** (1,244 vs 2,186) because only 16S rRNA reads are classified
- **Pseudomonas abundance drops significantly** when restricted to 16S reads (17.56% → 7.91%), suggesting genome-wide classification inflates its representation
- **Homo** (human) contamination at 3.71% in extracted-16S MGS — higher than Pipeline 2 (0.26%), possibly due to human rRNA sequences being captured by SortMeRNA

> **Note:** Pipeline 3 uses SortMeRNA (SILVA rRNA database) to extract 16S reads, then Kraken2/Bracken (full RefSeq standard database) for classification. The 16S amplicon side uses the NCBI RefSeq 16S V4 NB classifier in QIIME2. Both sides use NCBI taxonomy, so genus names match directly for most taxa.
