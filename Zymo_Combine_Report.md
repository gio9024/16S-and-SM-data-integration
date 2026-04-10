# Zymo Combined Pipeline Comparison Report

**Generated:** 2026-04-10
**Dataset:** ZymoBIOMICS Microbial Community Standard (D6305)
**Benchmarking:** TP = any Zymo genus present; FP = non-Zymo genera > 0.01% relative abundance

---

## 1. Pipeline Overview

| Pipeline | 16S Side | MGS Side | Shared Database |
|----------|----------|----------|-----------------|
| **Pipeline 1** | DADA2 + Greengenes2 classifier | Bowtie2 + WoLr2 + Woltka (Greengenes2) | Greengenes2 (GTDB taxonomy) |
| **Pipeline 2** | DADA2 + NCBI RefSeq 16S V4 NB classifier | Kraken2 + Bracken (full RefSeq standard DB) | NCBI taxonomy |
| **Pipeline 3** | DADA2 + NCBI RefSeq 16S V4 NB classifier | SortMeRNA extraction → Kraken2 + Bracken (full RefSeq standard DB) | NCBI taxonomy |

> **Note:** Pipeline 2 and Pipeline 3 share the same 16S amplicon classification (NCBI RefSeq 16S V4 classifier), so their 16S-side results are identical. Pipeline 3 MGS differs from Pipeline 2 MGS in that only SortMeRNA-extracted 16S reads (not all raw reads) are classified.

### Sample IDs

**16S samples (6):** NP0440-MB5_1, NP0440-MB5_2, NP0553-MB1_1, NP0553-MB1_2, NP0610-MB1_1, NP0610-MB1_2

**MGS samples (4):** SC718268_CCGGAATT-ACCGAATG_L001, SC718268_TGGATCAC-GCATTGGT_L001, SC718268_CAACCTAG-AGGTCTGT_L001, SC718268_TCTAACGC-CGCCTTAT_L001

---

## 2. Zymo Ground Truth

The ZymoBIOMICS Microbial Community Standard (D6305) contains **10 organisms** — 8 bacteria and 2 fungi:

| # | Genus | Species | Domain |
|---|-------|---------|--------|
| 1 | Bacillus | *B. subtilis* | Bacteria |
| 2 | Enterococcus | *E. faecalis* | Bacteria |
| 3 | Escherichia | *E. coli* | Bacteria |
| 4 | Lactobacillus | *L. fermentum* | Bacteria |
| 5 | Listeria | *L. monocytogenes* | Bacteria |
| 6 | Pseudomonas | *P. aeruginosa* | Bacteria |
| 7 | Salmonella | *S. enterica* | Bacteria |
| 8 | Staphylococcus | *S. aureus* | Bacteria |
| 9 | Saccharomyces | *S. cerevisiae* | Fungi |
| 10 | Cryptococcus | *C. neoformans* | Fungi |

---

## 3. Benchmarking Summary

### Combined Results Table

| Pipeline | Side | TP (Detected) | FN (Missed) | FP (>0.01%) | Missed Genera |
|----------|------|:---:|:---:|:---:|---------------|
| **Pipeline 1** | 16S | **8/10** | 2 | 5 | Saccharomyces, Cryptococcus |
| **Pipeline 1** | MGS | **8/10** | 2 | 29 | Saccharomyces, Cryptococcus |
| **Pipeline 2** | 16S | **8/10** | 2 | 5 | Saccharomyces, Cryptococcus |
| **Pipeline 2** | MGS | **9/10** | 1 | 7 | Cryptococcus |
| **Pipeline 3** | 16S | **8/10** | 2 | 5 | Saccharomyces, Cryptococcus |
| **Pipeline 3** | MGS | **9/10** | 1 | 40 | Cryptococcus |

> **Pipeline 1 16S detail:** 6 genera resolved to genus level + 2 detected at family level only (Salmonella → unresolved `Enterobacteriaceae` at 11.61%; Enterococcus → unresolved `Enterococcaceae` at 8.95%). The GG2 classifier fails to resolve these families to genus.

> **Pipeline 2 & 3 16S detail:** 7 genera resolved to genus level + 1 detected at family level (Salmonella → unresolved `Enterobacteriaceae` at 11.61%). The NCBI RefSeq classifier successfully resolves Enterococcus to genus (8.92%) but still cannot distinguish Salmonella from Escherichia using the V4 region.

---

## 4. Pipeline 1 — Greengenes2 + Woltka

### 16S (DADA2 + GG2)

| Metric | Value |
|--------|-------|
| ✅ True Positives | **8/10** — 6 resolved to genus + 2 at family level |
| ❌ False Negatives | **2** — Saccharomyces, Cryptococcus (fungi — not in bacterial DB) |
| ⚠️ False Positives (>0.01%) | **5** — Streptococcus, Prevotella, Veillonella, Haemophilus, Gemella |

Key issues:
- **Salmonella** → detected as unresolved `Enterobacteriaceae` (11.61%) — V4 region can't distinguish *Salmonella* from *Escherichia*
- **Enterococcus** → detected as unresolved `Enterococcaceae` (8.95%) — GG2 classifier failed to resolve to genus

### MGS (Bowtie2 + Woltka + GG2)

| Metric | Value |
|--------|-------|
| ✅ True Positives | **8/10** — All 8 bacteria detected and resolved |
| ❌ False Negatives | **2** — Saccharomyces, Cryptococcus (fungi — not in WoLr2 DB) |
| ⚠️ False Positives (>0.01%) | **29** — Largest: Luteimonas_D (0.10%), Vagococcus_D (0.09%) |

Key observations:
- Woltka/GG2 uses GTDB taxonomy, producing suffixed names (e.g., *Bacillus_P*, *Enterococcus_H*, *Limosilactobacillus*)
- High FP count (29) likely due to the broad WoLr2 reference database with many closely related GTDB genera
- No fungi detected — WoLr2 is a prokaryotic genome database

---

## 5. Pipeline 2 — Kraken2/Bracken (Full RefSeq)

### 16S (DADA2 + NCBI RefSeq 16S V4 Classifier)

| Metric | Value |
|--------|-------|
| ✅ True Positives | **8/10** — 7 resolved to genus + 1 at family level |
| ❌ False Negatives | **2** — Saccharomyces, Cryptococcus (fungi — not in 16S DB) |
| ⚠️ False Positives (>0.01%) | **5** — Streptococcus, Prevotella, Veillonella, Gemella, Haemophilus |

Key improvement over Pipeline 1 16S:
- **Enterococcus** now resolved to genus (8.92%) — NCBI RefSeq classifier resolves this correctly
- Salmonella still unresolved (V4 limitation, not classifier limitation)

### MGS (Kraken2 + Bracken + Full RefSeq Standard DB)

| Metric | Value |
|--------|-------|
| ✅ True Positives | **9/10** — All 8 bacteria + Saccharomyces detected |
| ❌ False Negatives | **1** — Cryptococcus |
| ⚠️ False Positives (>0.01%) | **7** — Shigella (0.35%), Homo (0.26%), Citrobacter, Klebsiella, Enterobacter, Burkholderia, Actinomyces |

Key observations:
- **Saccharomyces** detected (0.0007%) — full RefSeq DB includes eukaryotic genomes
- **Shigella** FP (0.35%) — known *E. coli/Shigella* taxonomic ambiguity
- **Homo** FP (0.26%) — host DNA contamination
- **Fewest FP among all MGS pipelines** (7 vs 29 for P1, 40 for P3)
- Total classified reads: ~220M

---

## 6. Pipeline 3 — SortMeRNA + Kraken2/Bracken (16S RefSeq)

### 16S (DADA2 + NCBI RefSeq 16S V4 Classifier)

| Metric | Value |
|--------|-------|
| ✅ True Positives | **8/10** — Same as Pipeline 2 16S (identical classifier) |
| ❌ False Negatives | **2** — Saccharomyces, Cryptococcus |
| ⚠️ False Positives (>0.01%) | **5** — Same as Pipeline 2 16S |

### MGS (SortMeRNA → Kraken2 + Bracken + Full RefSeq Standard DB)

| Metric | Value |
|--------|-------|
| ✅ True Positives | **9/10** — All 8 bacteria + Saccharomyces detected |
| ❌ False Negatives | **1** — Cryptococcus |
| ⚠️ False Positives (>0.01%) | **40** — Homo (3.70%), Klebsiella (0.94%), Burkholderia (0.72%), Actinomyces (0.40%), Enterobacter (0.32%), Shigella (0.31%), Clostridioides (0.29%), ... |

Key observations:
- SortMeRNA extracts ~1.5% of raw reads as 16S (~3.8M reads)
- **Highest FP count** (40) among all pipelines — 16S extraction introduces classification noise
- **Homo** inflated to 3.70% (vs 0.26% in P2) — human rRNA sequences captured by SortMeRNA
- Total classified reads: ~3.8M (vs ~220M for P2 MGS)

---

## 7. Pipeline MGS Side — Head-to-Head Comparison

### Zymo Expected Genera — Relative Abundance (%)

| Expected Genus | P1 MGS (Woltka) | P2 MGS (Kraken2) | P3 MGS (SortMeRNA+K2) | Zymo Theoretical |
|---------------|:---:|:---:|:---:|:---:|
| Bacillus | 14.82 | 12.72 | 18.95 | 17.4 |
| Enterococcus | 8.11 | 10.18 | 5.93 | 9.9 |
| Escherichia | 16.64 | 11.79 | 8.83 | 10.1 |
| Lactobacillus¹ | 10.46 | 9.19 | 8.98 | 18.4 |
| Listeria | 11.37 | 10.32 | 10.96 | 14.1 |
| Pseudomonas | 8.87 | 17.56 | 7.91 | 4.2 |
| Salmonella | 16.96 | 16.72 | 17.92 | 10.4 |
| Staphylococcus | 11.18 | 10.61 | 11.79 | 15.5 |
| Saccharomyces | ❌ | 0.0007 | 0.0003 | — |
| Cryptococcus | ❌ | ❌ | ❌ | — |

¹ Reported as *Limosilactobacillus* in GTDB/updated NCBI taxonomy (2020 reclassification of *L. fermentum*)

### Performance Metrics

| Metric | P1 MGS | P2 MGS | P3 MGS |
|--------|:---:|:---:|:---:|
| True Positives | 8/10 | **9/10** | **9/10** |
| False Negatives | 2 (fungi) | 1 | 1 |
| False Positives (>0.01%) | 29 | **7** | 40 |
| Total genera detected | 5,674 | 2,186 | 1,244 |
| Total classified reads | 351M | 220M | 3.8M |

---

## 8. Pipeline 16S Side — Comparison

| Metric | P1 16S (GG2) | P2/P3 16S (NCBI RefSeq) |
|--------|:---:|:---:|
| True Positives | 8/10 | 8/10 |
| Genus-level resolution | 6/8 bacteria | 7/8 bacteria |
| Enterococcus resolved? | ❌ (family only) | ✅ (genus) |
| Salmonella resolved? | ❌ (family only) | ❌ (family only) |
| False Positives (>0.01%) | 5 | 5 |
| Total genera detected | 22 | 20 |
| Taxonomy system | GTDB | NCBI |

---

## 9. Key Findings

### Sensitivity (True Positive Detection)
- **MGS pipelines** outperform 16S for detecting Zymo genera
- **P2 & P3 MGS detect 9/10** genera — including the fungus *Saccharomyces* (absent in P1 MGS due to prokaryotic-only WoLr2 database)
- **All 16S pipelines detect 8/10** — fungi are not amplified by bacterial 16S primers
- **Salmonella** is consistently missed by 16S (V4 region limitation) but detected by all MGS pipelines
- **Cryptococcus** is missed by all pipelines

### Specificity (False Positive Control)
- **Pipeline 2 MGS has the fewest FP (7)** — best balance of sensitivity and specificity
- **Pipeline 1 MGS (Woltka/GG2)** has 29 FP — GTDB-based WoLr2 database creates many low-level genus assignments
- **Pipeline 3 MGS** has the most FP (40) — SortMeRNA 16S extraction introduces classification noise and inflates human contamination (3.7%)
- **All 16S pipelines** have exactly 5 FP — consistent low-level contaminants (*Streptococcus, Prevotella, Veillonella, Gemella, Haemophilus*)

### Taxonomy Resolution
- **GG2 (Pipeline 1)** uses GTDB taxonomy with suffixed genus names (e.g., *Bacillus_P*, *Enterococcus_H*, *Limosilactobacillus*)
- **NCBI RefSeq (Pipelines 2 & 3)** uses standard NCBI taxonomy with traditional names
- **NCBI RefSeq 16S classifier** resolves Enterococcus to genus, while GG2 classifier does not
- Neither 16S classifier resolves Salmonella (V4 region limitation)

### Overall Rankings

| Rank | Pipeline | Strengths | Weaknesses |
|------|----------|-----------|------------|
| 1 | **P2 MGS (Kraken2/Bracken)** | 9/10 TP, fewest FP (7) | Shigella/Homo contamination |
| 2 | **P1 MGS (Woltka)** | 8/10 TP, resolved all bacteria | No fungi, high FP (29), GTDB names |
| 3 | **P3 MGS (SortMeRNA+K2)** | 9/10 TP | Most FP (40), Homo inflated to 3.7% |
| 4 | **P2/P3 16S (NCBI RefSeq)** | 8/10 TP, 5 FP, Enterococcus resolved | No fungi, Salmonella unresolved |
| 5 | **P1 16S (GG2)** | 8/10 TP, 5 FP | No fungi, Salmonella & Enterococcus unresolved |

---

## 10. Genus Tables Location

All genus-level OTU tables are available in:
`DataSets/Zymobiomics_Data/results_delivery/`

| File | Pipeline | Side |
|------|----------|------|
| `pipeline1_16S_otu_table_genus.tsv` | Pipeline 1 | 16S (GG2) |
| `pipeline1_MGS_otu_table_genus.tsv` | Pipeline 1 | MGS (Woltka) |
| `pipeline2_16S_otu_table_genus.tsv` | Pipeline 2 | 16S (NCBI RefSeq) |
| `pipeline2_MGS_otu_table_genus.tsv` | Pipeline 2 | MGS (Kraken2/Bracken) |
| `pipeline3_16S_otu_table_genus.tsv` | Pipeline 3 | 16S (NCBI RefSeq) |
| `pipeline3_MGS_otu_table_genus.tsv` | Pipeline 3 | MGS (SortMeRNA+K2) |
