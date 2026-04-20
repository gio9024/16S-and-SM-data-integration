# Patrick SRA Dataset — Combined Pipeline Report

**Generated:** 2026-04-20  
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

## 2. Pipeline Completion Status

✅ All five output tables generated successfully as of 2026-04-20.

| Output File | Pipeline | Side | Status | Completed |
|-------------|----------|------|--------|-----------|
| `results/patrick/pipeline1/16S/otu_table_genus.tsv` | Pipeline 1 | 16S (GG2) | ✅ Done | Apr 20 02:17 |
| `results/patrick/pipeline1/MGS/otu_table_genus.tsv` | Pipeline 1 | MGS (Woltka) | ✅ Done | Apr 19 21:14 |
| `results/patrick/pipeline2/MGS/otu_table_genus.tsv` | Pipeline 2 | MGS (Kraken2/Bracken) | ✅ Done | Apr 19 21:24 |
| `results/patrick/pipeline3/16S/otu_table_genus.tsv` | Pipeline 3 | 16S (RefSeq) | ✅ Done | Apr 20 02:21 |
| `results/patrick/pipeline3/MGS/otu_table_genus.tsv` | Pipeline 3 | MGS (SortMeRNA+K2) | ✅ Done | Apr 19 22:01 |

**Intermediate output counts (all 107/107):**

| Step | Count | Expected |
|------|-------|----------|
| P1 MGS — Bowtie2 SAM alignments | 107 | 107 ✅ |
| P2 MGS — Kraken2 `.kreport` files | 107 | 107 ✅ |
| P2 MGS — Bracken genus outputs | 107 | 107 ✅ |
| P3 MGS — SortMeRNA extracted reads | 107 | 107 ✅ |
| P3 MGS — Kraken2 `.kreport` files | 107 | 107 ✅ |
| P3 MGS — Bracken genus outputs | 107 | 107 ✅ |

---

## 3. Output Summary Table

| Pipeline | Side | Samples | Genera Detected | Total Classified Reads |
|----------|------|:---:|:---:|:---:|
| **Pipeline 1** | 16S (GG2) | 107 | 55 (40 genus-level named) | 14,882 |
| **Pipeline 1** | MGS (Woltka/GG2) | 107 | 5,073 | 4.42 billion |
| **Pipeline 2** | 16S (RefSeq, shared) | — | *(same as P3 16S)* | — |
| **Pipeline 2** | MGS (Kraken2/Bracken) | 107 | 3,543 | 3.09 billion |
| **Pipeline 3** | 16S (RefSeq) | 107 | 50 (36 genus-level named) | 14,882 |
| **Pipeline 3** | MGS (SortMeRNA+K2) | 107 | 2,286 | 49.1 million |

> **Note:** Pipeline 2 and Pipeline 3 share the same 16S output file (`results/patrick/pipeline3/16S/otu_table_genus.tsv`). The 14,882 total 16S reads is the ASV count classified from 107 samples combined.

---

## 4. Pipeline 1 — Greengenes2 + Woltka

### 16S (DADA2 + GG2)

| Metric | Value |
|--------|-------|
| Samples | 107 |
| Total ASV reads | 14,882 |
| Genera detected | 55 rows (40 with named genus-level assignments) |
| Taxonomy system | GTDB (GreenGenes2) — suffixed genus names |
| Classification | `p__Bacillota_A_368345` dominant (Clostridia-type Firmicutes) |

**Top genera by total read count (GTDB names):**

| Rank | Genus (GTDB) | Total Reads |
|------|--------------|:-----------:|
| 1 | *Clostridium_T* | 7,103 |
| 2 | *Phocaeicola_A* (Bacteroides-like) | 680 |
| 3 | *CAG-349* | 227 |
| 4 | *Thomasclavelia* | 200 |
| 5 | *PeH17* | 78 |
| 6 | *Dysosmobacter* | 64 |
| 7 | *Prevotella* | 62 |
| 8 | *Bifidobacterium_388775* | 56 |

Key observations:
- **GTDB taxonomy** produces renamed/suffixed genus identifiers (e.g., *Bacteroides_H_857956*, *Phocaeicola_A*, *Blautia_A_141781*)
- Dominant phyla: Bacillota_A (≈ Firmicutes) and Bacteroidota — consistent with gut microbiome
- 15 rows (~27%) are unresolved at genus level (`__`)

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
- **5,073 genera detected** — highest genus diversity among all pipelines, reflecting WoLr2's broad prokaryotic coverage
- No eukaryotic reads (WoLr2 is a prokaryotic genome database)
- GTDB suffixed names require mapping to NCBI names for cross-pipeline comparison

---

## 5. Pipeline 2 — Kraken2/Bracken (Full RefSeq)

### 16S (DADA2 + NCBI RefSeq 16S V4 Classifier)

*(Shared with Pipeline 3 — see Section 6)*

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

## 6. Pipeline 3 — SortMeRNA + Kraken2/Bracken (16S RefSeq)

### 16S (DADA2 + NCBI RefSeq 16S V4 Classifier)

| Metric | Value |
|--------|-------|
| Samples | 107 |
| Total ASV reads | 14,882 (same pool as P1 16S) |
| Genera detected | 50 rows (36 with named genus-level assignments) |
| Taxonomy system | NCBI taxonomy |

**Top genera by total read count (NCBI names):**

| Rank | Genus (NCBI) | Total Reads |
|------|--------------|:-----------:|
| 1 | *Clostridium* | 8,250 |
| 2 | *Bacteroides* | 760 |
| 3 | *Erysipelatoclostridium* | 205 |
| 4 | *Marseillibacter* | 64 |
| 5 | *Tyzzerella* | 61 |
| 6 | *Prevotella* | 56 |
| 7 | *Bifidobacterium* | 56 |
| 8 | *Romboutsia* | 50 |

Key observations:
- Same DADA2 ASVs as P1 16S, reclassified with NCBI RefSeq V4 classifier instead of GG2
- **Dominant genus is *Clostridium*** (8,250 reads) rather than the GG2-equivalent *Clostridium_T* → direct concordance confirmed between classifiers
- *Bacteroides* (NCBI) maps to *Phocaeicola_A* (GTDB) at the top, slightly different ranking
- 14 rows (~28%) are unresolved at genus level — consistent with P1 16S

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

## 7. Pipeline MGS Side — Head-to-Head Comparison

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

## 8. Pipeline 16S Side — Comparison

| Metric | P1 16S (GG2) | P3/P2 16S (NCBI RefSeq) |
|--------|:---:|:---:|
| Samples | 107 | 107 |
| Total classified ASVs | 14,882 | 14,882 |
| Genera detected (rows) | 55 | 50 |
| Genus-level named rows | 40 | 36 |
| Top genus | *Clostridium_T* (7,103) | *Clostridium* (8,250) |
| Unresolved (%) | ~27% | ~28% |
| Taxonomy system | GTDB | NCBI |
| Cross-pipeline name mapping | ⚠️ Requires GTDB→NCBI mapping | ✅ Direct |

Key findings:
- Both classifiers agree on the dominant genus (*Clostridium_T* ↔ *Clostridium*)
- *Bacteroides* / *Bacteroides-like* genera rank 2nd in both
- Unresolved rate (~27–28%) is similar between classifiers, suggesting the resolution limitation is the V4 region and read depth rather than the classifier

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
| 4 | **P2/P3 16S (NCBI RefSeq)** | NCBI names, consistent with MGS taxonomy | Limited depth (14,882 reads), ~28% unresolved |
| 5 | **P1 16S (GG2)** | GTDB taxonomy | GTDB names, ~27% unresolved, requires remapping |

---

## 10. Genus Tables Location

All genus-level OTU tables are available at:

| File | Pipeline | Side |
|------|----------|------|
| `results/patrick/pipeline1/16S/otu_table_genus.tsv` | Pipeline 1 | 16S (GG2) |
| `results/patrick/pipeline1/MGS/otu_table_genus.tsv` | Pipeline 1 | MGS (Woltka) |
| `results/patrick/pipeline1/MGS/otu_table_full.tsv` | Pipeline 1 | MGS (Woltka, species-level) |
| `results/patrick/pipeline2/MGS/otu_table_genus.tsv` | Pipeline 2 | MGS (Kraken2/Bracken) |
| `results/patrick/pipeline3/16S/otu_table_genus.tsv` | Pipeline 3 | 16S (NCBI RefSeq) — shared by P2 |
| `results/patrick/pipeline3/MGS/otu_table_genus.tsv` | Pipeline 3 | MGS (SortMeRNA+K2) |

---

## 11. Next Steps

- [ ] **Cross-pipeline genus-level comparison**: Map GTDB names (P1) to NCBI names (P2/P3) using the GG2 taxonomy TSV for a unified comparison table
- [ ] **Alpha diversity analysis**: Compute Shannon index, Observed species, Chao1 per pipeline across 107 samples
- [ ] **Beta diversity analysis**: PCoA/PERMANOVA per pipeline to assess sample clustering (BCH-F vs BCH-h)
- [ ] **Host contamination removal**: Filter *Homo* reads from P2/P3 MGS for downstream analysis
- [ ] **Differential abundance testing**: Compare BCH-F vs BCH-h groups per pipeline
- [ ] **Integration with Zymo benchmark**: Use Zymo performance metrics (Section 9 of Zymo_Combine_Report.md) to guide interpretation of Patrick results
