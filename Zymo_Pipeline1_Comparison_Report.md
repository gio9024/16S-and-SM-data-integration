# Zymo Pipeline 1 — 16S vs MGS Taxonomy Comparison Report

**Generated:** 2026-04-07 09:45
**Pipeline:** Greengenes2 + Woltka (MGS) / DADA2 + GG2 classifier (16S)

---

## 1. Overview

| Metric | 16S (DADA2 + GG2) | MGS (Woltka + GG2) |
|--------|-------------------|---------------------|
| Samples | 6 | 4 |
| Total genera detected | 22 | 5674 |
| Total read counts | 241,325 | 351,401,527 |

### Sample IDs

**16S samples:**
- `NP0440-MB5_1`
- `NP0440-MB5_2`
- `NP0553-MB1_1`
- `NP0553-MB1_2`
- `NP0610-MB1_1`
- `NP0610-MB1_2`

**MGS samples:**
- `SC718268_CAACCTAG-AGGTCTGT_L001`
- `SC718268_CCGGAATT-ACCGAATG_L001`
- `SC718268_TCTAACGC-CGCCTTAT_L001`
- `SC718268_TGGATCAC-GCATTGGT_L001`

---

## 2. Genus-Level Overlap

| Category | Count |
|----------|-------|
| Shared genera (both methods) | 18 |
| Unique to 16S | 4 |
| Unique to MGS | 5656 |
| Total unique genera | 5678 |

---

## 3. Top 20 Genera by Total Counts

### 16S (DADA2 + GG2)

| Rank | Genus | Total Counts | Mean Rel. Abundance (%) | Also in MGS? |
|------|-------|-------------|------------------------|--------------|
| 1 | Staphylococcus | 47,867 | 19.82 | ✅ |
| 2 | Bacillus_P_294101 | 44,188 | 18.27 | ✅ |
| 3 | Listeria_A | 38,023 | 15.77 | ✅ |
| 4 | d__Bacteria;p__Pseudomonadota;c__Gammaproteobacteria;o__Enterobacterales_737866;f__Enterobacteriaceae_A_725029;__ | 28,014 | 11.63 | ❌ |
| 5 | Escherichia | 26,151 | 10.84 | ✅ |
| 6 | d__Bacteria;p__Bacillota_I;c__Bacilli_A;o__Lactobacillales;f__Enterococcaceae;__ | 21,609 | 8.92 | ❌ |
| 7 | Limosilactobacillus | 21,591 | 9.01 | ✅ |
| 8 | Pseudomonas_B_650326 | 13,327 | 5.53 | ✅ |
| 9 | Streptococcus | 168 | 0.07 | ✅ |
| 10 | Veillonella_A | 107 | 0.04 | ✅ |
| 11 | Prevotella | 107 | 0.04 | ✅ |
| 12 | Haemophilus_D_735815 | 44 | 0.02 | ✅ |
| 13 | Gemella | 44 | 0.02 | ✅ |
| 14 | Unassigned;__;__;__;__;__ | 22 | 0.01 | ❌ |
| 15 | d__Bacteria;__;__;__;__;__ | 15 | 0.01 | ❌ |
| 16 | Phocaeicola_A | 10 | 0.00 | ✅ |
| 17 | Rothia | 8 | 0.00 | ✅ |
| 18 | Bacteroides_H_857956 | 8 | 0.00 | ✅ |
| 19 | Neisseria_563205 | 8 | 0.00 | ✅ |
| 20 | Gemmiger_A_73129 | 6 | 0.00 | ✅ |

### MGS (Woltka + GG2)

| Rank | Genus | Total Counts | Mean Rel. Abundance (%) | Also in 16S? |
|------|-------|-------------|------------------------|--------------|
| 1 | Salmonella | 59,601,880 | 16.96 | ❌ |
| 2 | Escherichia | 58,465,477 | 16.64 | ✅ |
| 3 | Bacillus_P_294101 | 52,089,678 | 14.82 | ✅ |
| 4 | Listeria_A | 39,962,617 | 11.37 | ✅ |
| 5 | Staphylococcus | 39,284,885 | 11.18 | ✅ |
| 6 | Limosilactobacillus | 36,787,685 | 10.46 | ✅ |
| 7 | Pseudomonas_B_650326 | 31,141,085 | 8.87 | ✅ |
| 8 | Enterococcus_H_360604 | 28,511,404 | 8.11 | ❌ |
| 9 | Luteimonas_D | 361,334 | 0.10 | ❌ |
| 10 | Vagococcus_D | 323,224 | 0.09 | ❌ |
| 11 | Kluyvera_724519 | 242,808 | 0.07 | ❌ |
| 12 | Enterococcus_B | 223,786 | 0.06 | ❌ |
| 13 | Citrobacter_A_692098 | 217,304 | 0.06 | ❌ |
| 14 | Gallibacterium | 192,377 | 0.05 | ❌ |
| 15 | Acinetobacter | 157,868 | 0.04 | ❌ |
| 16 | Klebsiella_724518 | 157,842 | 0.04 | ❌ |
| 17 | Streptococcus | 149,440 | 0.04 | ✅ |
| 18 | Absicoccus | 128,597 | 0.04 | ❌ |
| 19 | Campylobacter_A_477346 | 117,436 | 0.03 | ❌ |
| 20 | Enterococcus_E | 111,490 | 0.03 | ❌ |

---

## 4. Shared Genera — Mean Relative Abundance Comparison

Top shared genera ranked by average relative abundance across both methods:

| Genus | 16S Mean RA (%) | MGS Mean RA (%) | Ratio (MGS/16S) |
|-------|----------------|----------------|-----------------|
| Bacillus_P_294101 | 18.27 | 14.82 | 0.81 |
| Staphylococcus | 19.82 | 11.18 | 0.56 |
| Escherichia | 10.84 | 16.64 | 1.54 |
| Listeria_A | 15.77 | 11.37 | 0.72 |
| Limosilactobacillus | 9.01 | 10.46 | 1.16 |
| Pseudomonas_B_650326 | 5.53 | 8.87 | 1.61 |
| Streptococcus | 0.07 | 0.04 | 0.61 |
| Veillonella_A | 0.04 | 0.00 | 0.00 |
| Prevotella | 0.04 | 0.00 | 0.00 |
| Haemophilus_D_735815 | 0.02 | 0.00 | 0.00 |
| Gemella | 0.02 | 0.00 | 0.00 |
| Phocaeicola_A | 0.00 | 0.00 | 0.01 |
| Bacteroides_H_857956 | 0.00 | 0.00 | 0.02 |
| Rothia | 0.00 | 0.00 | 0.27 |
| Neisseria_563205 | 0.00 | 0.00 | 0.09 |
| Gemmiger_A_73129 | 0.00 | 0.00 | 0.01 |
| Dorea_A | 0.00 | 0.00 | 0.00 |
| Agathobacter_164117 | 0.00 | 0.00 | 0.00 |

---

## 5. Genera Unique to One Method

### Unique to 16S (top 15 by mean RA)

| Genus | Mean Rel. Abundance (%) |
|-------|------------------------|
| d__Bacteria;p__Pseudomonadota;c__Gammaproteobacteria;o__Enterobacterales_737866;f__Enterobacteriaceae_A_725029;__ | 11.6308 |
| d__Bacteria;p__Bacillota_I;c__Bacilli_A;o__Lactobacillales;f__Enterococcaceae;__ | 8.9159 |
| Unassigned;__;__;__;__;__ | 0.0093 |
| d__Bacteria;__;__;__;__;__ | 0.0062 |

### Unique to MGS (top 15 by mean RA)

| Genus | Mean Rel. Abundance (%) |
|-------|------------------------|
| Salmonella | 16.9636 |
| Enterococcus_H_360604 | 8.1127 |
| Luteimonas_D | 0.1029 |
| Vagococcus_D | 0.0919 |
| Kluyvera_724519 | 0.0690 |
| Enterococcus_B | 0.0637 |
| Citrobacter_A_692098 | 0.0618 |
| Gallibacterium | 0.0547 |
| Klebsiella_724518 | 0.0449 |
| Acinetobacter | 0.0449 |
| Absicoccus | 0.0366 |
| Campylobacter_A_477346 | 0.0334 |
| Enterococcus_E | 0.0317 |
| Trichococcus | 0.0316 |
| Enterobacter_B_713587 | 0.0275 |

---

## 6. Summary & Key Observations

- **16S** detected **22** genera across **6** samples (DADA2 + GG2 Naive Bayes classifier)
- **MGS** detected **5674** genera across **4** samples (Bowtie2 + WoLr2 + Woltka OGU)
- **18** genera were shared between both methods (18/5678 = 0.3% of total)
- **4** genera (18.2%) were unique to 16S
- **5656** genera (99.7%) were unique to MGS

> **Note:** Both methods use the same Greengenes2 taxonomy, enabling direct genus-label comparison without additional harmonization.
