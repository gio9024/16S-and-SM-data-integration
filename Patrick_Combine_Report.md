# Patrick SRA Dataset — Combined Pipeline Report

**Generated:** 2026-04-20 | **Updated:** 2026-04-27 (16S V3-V4 corrected rerun)  
**Dataset:** Patrick SRA dataset (BCH Cohort — Pediatric Gut Microbiome)  
**Samples:** 107 samples (43 BCH-F stool, 64 BCH-h stool)  
**Note:** This is a real human gut microbiome cohort — no reference ground truth. Report focuses on pipeline completion, output characteristics, and cross-pipeline concordance.

---

## 1. Pipeline Overview

| Pipeline | 16S Side | MGS Side | Shared Database |
|----------|----------|----------|-----------------|
| **Pipeline 1** | DADA2 + Greengenes2 classifier | Bowtie2 + WoLr2 + Woltka (Greengenes2) | Greengenes2 (GTDB taxonomy) |
| **Pipeline 2** | DADA2 + NCBI RefSeq 16S V4 NB classifier | Kraken2 + Bracken (full RefSeq standard DB) | NCBI taxonomy |
| **Pipeline 3** | DADA2 + NCBI RefSeq 16S V4 NB classifier | SortMeRNA extraction → Kraken2 + Bracken (full RefSeq standard DB) | NCBI taxonomy |

> **Note:** Pipeline 2 and Pipeline 3 share the same 16S amplicon classification (NCBI RefSeq 16S V4 classifier), so their 16S-side results are identical. Pipeline 3 MGS differs from Pipeline 2 MGS in that only SortMeRNA-extracted 16S reads (not all raw reads) are classified.

### Sample Information

**16S + MGS samples:** 107 paired samples  
- **BCH-F (stool, fecal):** 43 samples (BCH-F014 through BCH-F*)  
- **BCH-h (stool, human):** 64 samples (BCH-h*)  

---


## 2. Output Summary Table

| Pipeline | Side | Samples | Genera Detected | Total Classified Reads |
|----------|------|:---:|:---:|:---:|
| **Pipeline 1** | 16S (GG2) | 107 | 417 (331 genus-level named) | 9,194,967 |
| **Pipeline 1** | MGS (Woltka/GG2) | 107 | 5,073 | 4.42 billion |
| **Pipeline 2** | 16S (RefSeq, shared) | — | *(same as P3 16S)* | — |
| **Pipeline 2** | MGS (Kraken2/Bracken) | 107 | 3,543 | 3.09 billion |
| **Pipeline 3** | 16S (RefSeq) | 107 | 289 (231 genus-level named) | 9,194,967 |
| **Pipeline 3** | MGS (SortMeRNA+K2) | 107 | 2,286 | 49.1 million |

> **Note:** Pipeline 2 and Pipeline 3 share the same 16S ASVs (from corrected V3-V4 DADA2 rerun with trunc-len-f=240, trunc-len-r=200). The 9,194,967 total reads are non-chimeric merged reads from 107 samples (81.8% merge rate).

---

## 3. Pipeline 1 — Greengenes2 + Woltka

### 16S (DADA2 + GG2) — V3-V4 Corrected Rerun

| Metric | Value |
|--------|-------|
| Samples | 107 |
| Input reads | 20,940,816 |
| Filtered reads | 17,791,904 (85.0%) |
| Merged reads | 14,560,997 (81.8% merge rate) |
| Non-chimeric (classified) | 9,194,967 (43.9% of input) |
| Genera detected | 417 rows (331 with named genus-level assignments) |
| Taxonomy system | GTDB (GreenGenes2) — suffixed genus names |
| DADA2 parameters | trunc-len-f=240, trunc-len-r=200 (V3-V4 optimized) |

**Top genera by total read count (GTDB names):**

| Rank | Genus (GTDB) | Total Reads |
|------|--------------|:-----------:|
| 1 | *Bacteroides_H_857956* | 2,051,886 |
| 2 | *Prevotella* | 1,030,068 |
| 3 | *Agathobacter_164119* | 389,458 |
| 4 | *Faecalibacterium* | 318,988 |
| 5 | *Bifidobacterium_388775* | 248,974 |

Key observations:
- **V3-V4 rerun** corrected the previous 0.13% merge rate to 81.8% — recovering 9.19M non-chimeric reads (vs. 14,882 previously)
- **GTDB taxonomy** produces renamed/suffixed genus identifiers (e.g., *Bacteroides_H_857956*, *Agathobacter_164119*)
- Dominant phyla: Bacteroidota and Bacillota_A (≈ Firmicutes) — consistent with human gut microbiome
- 86 rows (~21%) are unresolved at genus level (`__`)

### MGS (Bowtie2 + Woltka + GG2)

| Metric | Value |
|--------|-------|
| Samples | 107 |
| Total classified reads | 4.42 billion |
| Genera detected | 5,073 |
| Taxonomy system | GTDB (WoLr2 database) |

**Top genera by total read count (GTDB names):**

| Rank | Genus (GTDB) | Total Reads |
|------|--------------|:-----------:|
| 1 | *Bacteroides_H_857956* | 795,156,592 |
| 2 | *Phocaeicola_A* | 682,917,114 |
| 3 | *Prevotella* | 620,839,272 |
| 4 | *Alistipes_A_871400* | 148,490,690 |
| 5 | *Agathobacter_164117* | 146,138,082 |
| 6 | *Faecalibacterium* | 126,877,506 |
| 7 | *Klebsiella_724518* | 107,213,819 |
| 8 | *Gemmiger_A_73129* | 99,946,795 |
| 9 | *Roseburia_A_166204* | 93,793,414 |
| 10 | *Blautia_A_141781* | 89,628,568 |

Key observations:
- **Largest total classified reads** (4.42B) — Bowtie2 + WoLr2 captures the full complement of bacterial reads
- Dominant genera (Bacteroides/Prevotella/Alistipes) are consistent with a healthy gut microbiome
- **5,073 genera detected** — highest genus diversity among all pipelines.

---

## 4. Pipeline 2 — Kraken2/Bracken (Full RefSeq)

### 16S (DADA2 + NCBI RefSeq 16S Full-Length Classifier)

*(Shared with Pipeline 3 — see Section 5, V3-V4 Corrected Rerun)*

### MGS (Kraken2 + Bracken + Full RefSeq Standard DB)

| Metric | Value |
|--------|-------|
| Samples | 107 |
| Total classified reads | 3.09 billion |
| Genera detected | 3,543 |
| Taxonomy system | NCBI taxonomy |
| Host reads (*Homo*) | 32,723,690 (1.06% of total) |

**Top genera by total read count (NCBI names):**

| Rank | Genus | Total Reads |
|------|-------|:-----------:|
| 1 | *Bacteroides* | 735,136,125 |
| 2 | *Phocaeicola* | 493,365,479 |
| 3 | *Segatella* | 479,981,905 |
| 4 | *Faecalibacterium* | 271,085,718 |
| 5 | *Blautia* | 98,359,466 |
| 6 | *Parabacteroides* | 85,160,544 |
| 7 | *Alistipes* | 72,513,840 |
| 8 | *Roseburia* | 62,663,078 |
| 9 | *Klebsiella* | 61,600,982 |
| 10 | *Bifidobacterium* | 54,668,976 |

Key observations:
- **Standard NCBI taxonomy** — genus names are directly comparable across studies
- *Bacteroides*, *Phocaeicola*, and *Segatella* (formerly *Prevotella copri* group) dominate — consistent with gut microbiome
- **Host contamination** (*Homo*): 1.06% of reads — low, within expected range after standard library prep
- *Klebsiella* detected at rank 9 (~2% of total) — commonly detected in gut samples; warrants monitoring for clinical context
- **3,543 genera detected** — fewer than P1 (NCBI taxonomy is more conservative than GTDB)

---

## 5. Pipeline 3 — SortMeRNA + Kraken2/Bracken (16S RefSeq)

### 16S (DADA2 + NCBI RefSeq 16S Full-Length Classifier) — V3-V4 Corrected Rerun

| Metric | Value |
|--------|-------|
| Samples | 107 |
| Non-chimeric reads | 9,194,967 (same ASV pool as P1 16S) |
| Genera detected | 289 rows (231 with named genus-level assignments) |
| Taxonomy system | NCBI taxonomy |

**Top genera by total read count (NCBI names):**

| Rank | Genus (NCBI) | Total Reads |
|------|--------------|:-----------:|
| 1 | *Bacteroides* | 2,080,754 |
| 2 | *Faecalibacterium* | 1,130,662 |
| 3 | *Prevotella* | 1,013,696 |
| 4 | *Blautia* | 443,201 |
| 5 | *Roseburia* | 264,763 |
| 6 | *Bifidobacterium* | 256,947 |
| 7 | *Escherichia* | 183,846 |
| 8 | *Ruminococcus* | 178,178 |

Key observations:
- Same DADA2 ASVs as P1 16S, reclassified with NCBI RefSeq full-length classifier instead of GG2
- **Dominant genus is *Bacteroides*** (2.08M reads) — concordant with P1's *Bacteroides_H_857956* as top genus
- **289 genera** closely matches the original paper's 291 genera (Guo et al. 2023, SILVA classifier)
- 58 rows (~20%) are unresolved at genus level — consistent with P1 16S

### MGS (SortMeRNA → Kraken2 + Bracken + Full RefSeq Standard DB)

| Metric | Value |
|--------|-------|
| Samples | 107 |
| Total classified reads | 49.1 million |
| Genera detected | 2,286 |
| Taxonomy system | NCBI taxonomy |
| Host reads (*Homo*) | 5,022,780 (**10.22%** of total) |

**Top genera by total read count (NCBI names):**

| Rank | Genus | Total Reads |
|------|-------|:-----------:|
| 1 | *Phocaeicola* | 6,478,993 |
| 2 | *Segatella* | 6,346,971 |
| 3 | *Bacteroides* | 5,578,971 |
| 4 | *Homo* | 5,022,780 |
| 5 | *Faecalibacterium* | 3,699,235 |
| 6 | *Blautia* | 2,603,568 |
| 7 | *Roseburia* | 1,211,011 |
| 8 | *Escherichia* | 1,105,061 |
| 9 | *Agathobacter* | 834,607 |
| 10 | *Bifidobacterium* | 787,624 |

Key observations:
- SortMeRNA extracts 16S-matching reads from WGS data (~49M total classified)
- **Host contamination elevated**: *Homo* at 10.22% — SortMeRNA captures human rRNA sequences, consistent with Zymo benchmark behavior (3.7% in 4-sample Zymo vs 10.2% in 107-sample human cohort)
- Core microbiome genera (*Phocaeicola*, *Segatella*, *Bacteroides*) still rank highest → taxonomy is biologically coherent
- **2,286 genera detected** — fewest among all MGS pipelines
- Total reads substantially lower than P2 (49M vs 3.09B) due to 16S-only extraction step

---

## 6. Pipeline MGS Side — Head-to-Head Comparison

### Top 10 Shared Genera — Relative Abundance (%) by Pipeline

> **Note:** P1 uses GTDB names; P2 and P3 use NCBI names. Mapping is approximate (e.g., *Bacteroides_H_857956* ≈ *Bacteroides*; *Phocaeicola_A* ≈ *Phocaeicola*).

| NCBI Genus | P1 MGS (Woltka/GG2) | P2 MGS (Kraken2) | P3 MGS (SortMeRNA+K2) |
|------------|:---:|:---:|:---:|
| *Bacteroides* / *Bacteroides_H* | ~18.0% | 23.8% | 11.4% |
| *Phocaeicola* / *Phocaeicola_A* | ~15.4% | 16.0% | 13.2% |
| *Prevotella* / *Segatella* | ~14.0% | 15.5% | 12.9% |
| *Faecalibacterium* | ~2.9% | 8.8% | 7.5% |
| *Blautia* | ~2.0% | 3.2% | 5.3% |
| *Roseburia* | ~2.1% | 2.0% | 2.5% |
| *Alistipes* | ~3.4% | 2.3% | 1.0% |
| *Bifidobacterium* | ~1.7% | 1.8% | 1.6% |
| *Klebsiella* | ~2.4% | 2.0% | 1.6% |
| *Homo* (host) | ❌ (not in WoLr2) | 1.06% | **10.22%** |

### Performance Summary

| Metric | P1 MGS (Woltka) | P2 MGS (Kraken2) | P3 MGS (SortMeRNA+K2) |
|--------|:---:|:---:|:---:|
| Total classified reads | 4.42B | 3.09B | 49.1M |
| Genera detected | 5,073 | 3,543 | 2,286 |
| Host (*Homo*) reads | N/A (prokaryotic DB) | 32.7M (1.06%) | 5.0M (10.22%) |
| Taxonomy system | GTDB | NCBI | NCBI |
| Cross-pipeline name concordance | ⚠️ Requires mapping | ✅ Direct | ✅ Direct |

---

## 7. Pipeline 16S Side — Comparison (V3-V4 Corrected Rerun)

| Metric | P1 16S (GG2) | P3/P2 16S (NCBI RefSeq) |
|--------|:---:|:---:|
| Samples | 107 | 107 |
| Total non-chimeric reads | 9,194,967 | 9,194,967 |
| Genera detected (rows) | 417 | 289 |
| Genus-level named rows | 331 | 231 |
| Top genus | *Bacteroides_H_857956* (2,051,886) | *Bacteroides* (2,080,754) |
| Unresolved (%) | ~21% | ~20% |
| Taxonomy system | GTDB | NCBI |
| Cross-pipeline name mapping | ⚠️ Requires GTDB→NCBI mapping | ✅ Direct |

Key findings:
- Both classifiers agree on the dominant genus (*Bacteroides_H_857956* ↔ *Bacteroides*) — top genus with ~2M reads each
- *Prevotella* ranks in top 3 for both classifiers
- P3's 289 genera closely matches the original paper's 291 genera (Guo et al. 2023)
- Unresolved rate (~20–21%) is improved from the previous broken run (~27–28%), reflecting better read quality after V3-V4 truncation correction
- DADA2 merge rate improved from 0.13% → 81.8% after fixing truncation parameters (F=240, R=200)

---

## 8. Genus Detection at 0.01% Relative Abundance Cutoff

> **Context:** For Zymo (mock community), the 0.01% cutoff was used to count **false positives** — genera that exceeded noise level but weren't in the true community. For Patrick (real human gut), there is no ground truth, so the same cutoff instead measures **how many genera survive noise filtering** — a proxy for biologically meaningful detection.

### 9.1 Cutoff-Based Detection Summary

| Pipeline | Side | Total Genera | >0.01% (mean RA) | >0.01% (any sample) | >0.01% (≥10% samples) | >0.01% (>50% samples) |
|----------|------|:---:|:---:|:---:|:---:|:---:|
| **Pipeline 1** | 16S (GG2) | 417 | *TBD* | *TBD* | *TBD* | *TBD* |
| **Pipeline 1** | MGS (Woltka) | 5,073 | 239 | 595 | 294 | 155 |
| **Pipeline 2** | MGS (Kraken2) | 3,543 | 143 | 446 | 195 | 93 |
| **Pipeline 3** | 16S (RefSeq) | 289 | *TBD* | *TBD* | *TBD* | *TBD* |
| **Pipeline 3** | MGS (SortMeRNA+K2) | 2,286 | 171 | 771 | 243 | 111 |

> **Note:** 16S cutoff analysis values marked *TBD* need to be recalculated with the corrected V3-V4 rerun data.

> **Column definitions:**
> - **>0.01% (mean RA)**: genera whose mean relative abundance across all 107 samples exceeds 0.01%
> - **>0.01% (any sample)**: genera exceeding 0.01% in at least 1 sample
> - **>0.01% (≥10% samples)**: genera exceeding 0.01% in ≥11 of 107 samples (robust detection)
> - **>0.01% (>50% samples)**: genera exceeding 0.01% in majority of samples (core microbiome)

### 9.2 Average Genera Per Sample Above 0.01% Cutoff

| Pipeline | Side | Mean Genera/Sample | Median | Min | Max |
|----------|------|-----------------:|:---:|:---:|:---:|
| **Pipeline 1** | 16S (GG2) | 3.4 | 3 | 0 | 12 |
| **Pipeline 1** | MGS (Woltka) | 168.6 | 175 | 54 | 255 |
| **Pipeline 2** | MGS (Kraken2) | 110.7 | 104 | 20 | 262 |
| **Pipeline 3** | 16S (RefSeq) | 2.9 | 2 | 0 | 8 |
| **Pipeline 3** | MGS (SortMeRNA+K2) | 133.0 | 122 | 50 | 365 |

> The low per-sample genus count on the 16S side (~3/sample) reflects the shallow depth and sparse nature of DADA2 classification across 107 samples at this cutoff.

### 9.3 Top Genera Above 0.01% (Mean Relative Abundance)

**Pipeline 1 — MGS (Woltka/GTDB), top 10 above cutoff:**

| Genus (GTDB) | Mean RA% | Samples >0.01% |
|--------------|:--------:|:--------------:|
| *Bacteroides_H_857956* | 17.83% | 106/107 |
| *Phocaeicola_A* | 15.64% | 105/107 |
| *Prevotella* | 13.90% | 106/107 |
| *Agathobacter_164117* | 3.48% | 105/107 |
| *Alistipes_A_871400* | 3.47% | 105/107 |
| *Faecalibacterium* | 2.95% | 105/107 |
| *Gemmiger_A_73129* | 2.33% | 105/107 |
| *Roseburia_A_166204* | 2.12% | 105/107 |
| *Blautia_A_141781* | 2.07% | 105/107 |
| *Parabacteroides_B_862066* | 2.01% | 105/107 |

**Pipeline 2 — MGS (Kraken2/NCBI), top 10 above cutoff:**

| Genus (NCBI) | Mean RA% | Samples >0.01% | Note |
|--------------|:--------:|:--------------:|------|
| *Bacteroides* | 23.44% | 106/107 | |
| *Phocaeicola* | 15.49% | 105/107 | |
| *Segatella* | 14.84% | 105/107 | |
| *Faecalibacterium* | 9.20% | 106/107 | |
| *Blautia* | 3.38% | 105/107 | |
| *Parabacteroides* | 2.74% | 106/107 | |
| *Alistipes* | 2.44% | 105/107 | |
| *Roseburia* | 2.11% | 105/107 | |
| *Agathobacter* | 1.86% | 105/107 | |
| *Bifidobacterium* | 1.78% | 104/107 | |
| *Homo* | 1.43% | **107/107** | ⚠️ Host DNA |

**Pipeline 3 — MGS (SortMeRNA+K2/NCBI), top 10 above cutoff:**

| Genus (NCBI) | Mean RA% | Samples >0.01% | Note |
|--------------|:--------:|:--------------:|------|
| *Phocaeicola* | 14.04% | 106/107 | |
| *Bacteroides* | 13.11% | 106/107 | |
| *Segatella* | 12.65% | 81/107 | |
| *Homo* | **8.21%** | **107/107** | ⚠️ Host rRNA |
| *Faecalibacterium* | 7.97% | 106/107 | |
| *Blautia* | 5.41% | 105/107 | |
| *Roseburia* | 2.41% | 105/107 | |
| *Agathobacter* | 1.83% | 104/107 | |
| *Escherichia* | 1.76% | 101/107 | |
| *Parabacteroides* | 1.70% | 105/107 | |

### 9.4 Key Observations from 0.01% Cutoff Analysis

**Noise filtering effect:**
- **P1 MGS**: 5,073 total genera → 239 above mean 0.01% cutoff (~4.7% retained) — indicating ~95% of genera are ultra-low-abundance noise
- **P2 MGS**: 3,543 total genera → 143 above mean 0.01% cutoff (~4.0% retained)
- **P3 MGS**: 2,286 total genera → 171 above mean 0.01% cutoff (~7.5% retained) — higher retention rate suggests 16S-extracted reads are enriched for real signal

**Core microbiome at >50% prevalence:**
- **P1 MGS**: 155 genera present in majority of samples — richest core
- **P3 MGS**: 111 genera in majority of samples
- **P2 MGS**: 93 genera in majority of samples — most conservative core
- **16S (both)**: only 1 genus present in majority of samples at 0.01% cutoff — reflects sparse per-sample depth

**Host contamination (*Homo*) comparison:**

| Pipeline | *Homo* Mean RA% | Present in all 107 samples? |
|----------|:---:|:---:|
| P1 MGS (Woltka) | N/A (not in WoLr2) | — |
| P2 MGS (Kraken2) | 1.43% | ✅ Yes |
| P3 MGS (SortMeRNA+K2) | **8.21%** | ✅ Yes |

*Homo* appears in **every sample** for P2 and P3 — it should be removed for downstream microbiome analyses. P3 human contamination (8.21% mean RA) is ~5.7× higher than P2 (1.43%), driven by SortMeRNA capturing human 18S/rRNA sequences.

**Cutoff General Stats:**

| Context | Pipeline | Total genera | Above 0.01% (any sample) |
|---------|----------|:---:|:---:|
| Patrick (human, 107 samples) | P1 MGS | 5,073 | 595 |
| Patrick (human, 107 samples) | P2 MGS | 3,543 | 446 |
| Patrick (human, 107 samples) | P3 MGS | 2,286 | 771 |


---

## 9. Key Findings

### Biological Concordance Across Pipelines
- **Core gut microbiome genera are consistently detected across all three pipelines**: *Bacteroides*, *Phocaeicola*, *Segatella/Prevotella*, *Faecalibacterium*, *Blautia*, *Roseburia*, *Bifidobacterium*
- **Firmicutes and Bacteroidota dominate** all 16S and MGS outputs — consistent with a human pediatric gut microbiota
- *Clostridium* (16S) and *Faecalibacterium* (MGS) prominently detected across all pipelines

### Taxonomy and Cross-Pipeline Comparability
- **Pipeline 1 (GTDB)** uses renamed/suffixed genus identifiers that require a GTDB→NCBI mapping step before direct comparison with P2/P3
- **Pipelines 2 and 3 are directly comparable** — both use NCBI taxonomy and the same 16S classifier
- *Segatella* (P2/P3 NCBI) corresponds to *Prevotella copri* group — shared top-5 genus across all MGS pipelines under different names

### Host Contamination
- **Pipeline 1 MGS**: No host reads — WoLr2 is prokaryotic-only
- **Pipeline 2 MGS**: *Homo* = 1.06% — within expected range for human stool sequencing
- **Pipeline 3 MGS**: *Homo* = 10.22% — elevated due to SortMeRNA capturing human rRNA sequences (consistent with Zymo benchmark findings)

### Pipeline Diversity Profiles
- **Pipeline 1 MGS** detects the most genera (5,073) — WoLr2's comprehensive GTDB-based database maximizes coverage
- **Pipeline 2 MGS** has the second-most genera (3,543) with NCBI-consistent names
- **Pipeline 3 MGS** detects the fewest genera (2,286) — 16S-extraction limits scope to rRNA-matching reads only

### Overall Pipeline Characteristics for Human Gut Cohort

| Rank | Pipeline | Strengths | Considerations |
|------|----------|-----------|----------------|
| 1 | **P2 MGS (Kraken2/Bracken)** | Best sensitivity + NCBI names + low host contamination (1%) | Some genera overlap ambiguities (*Klebsiella*) |
| 2 | **P1 MGS (Woltka/GG2)** | Highest genus diversity (5,073), largest read count | GTDB names require remapping; no eukaryotes |
| 3 | **P3 MGS (SortMeRNA+K2)** | 16S-targeted, fewer false genera | Elevated host contamination (10%), fewer reads |
| 4 | **P2/P3 16S (NCBI RefSeq)** | NCBI names, consistent with MGS taxonomy, 289 genera | ~20% unresolved |
| 5 | **P1 16S (GG2)** | GTDB taxonomy, 417 genera | GTDB names, ~21% unresolved, requires remapping |

---

## 10. Genus Tables Location

All genus-level OTU tables are available at:

| File | Pipeline | Side |
|------|----------|------|
| `results/patrick/pipeline1/16S_v34/otu_table_genus.tsv` | Pipeline 1 | 16S (GG2) — V3-V4 corrected |
| `results/patrick/pipeline1/16S/otu_table_genus.tsv` | Pipeline 1 | 16S (GG2) — original (broken V4 truncation) |
| `results/patrick/pipeline1/MGS/otu_table_genus.tsv` | Pipeline 1 | MGS (Woltka) |
| `results/patrick/pipeline1/MGS/otu_table_full.tsv` | Pipeline 1 | MGS (Woltka, species-level) |
| `results/patrick/pipeline2/MGS/otu_table_genus.tsv` | Pipeline 2 | MGS (Kraken2/Bracken) |
| `results/patrick/pipeline3/16S_v34/otu_table_genus.tsv` | Pipeline 3 | 16S (NCBI RefSeq) — V3-V4 corrected, shared by P2 |
| `results/patrick/pipeline3/16S/otu_table_genus.tsv` | Pipeline 3 | 16S (NCBI RefSeq) — original (broken V4 truncation) |
| `results/patrick/pipeline3/MGS/otu_table_genus.tsv` | Pipeline 3 | MGS (SortMeRNA+K2) |

