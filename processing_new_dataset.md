# Processing a New Dataset Through All Three Pipelines

This guide documents how the **Patrick SRA dataset** was processed through the three metagenomics pipelines, written as a generalizable reference for processing any future dataset.

---

## Overview

Each dataset runs through three independent pipelines that compare **16S amplicon** vs. **shotgun metagenomics (MGS)** classification using different tools and databases.  

| Pipeline | 16S Side | MGS Side | Database |
|---|---|---|---|
| **Pipeline 1** | DADA2 + GreenGenes2 (QIIME2) | Bowtie2 → Woltka | WoLr2 / GG2 |
| **Pipeline 2** | DADA2 + RefSeq 16S (QIIME2) | Kraken2 + Bracken | RefSeq (k2_standard) |
| **Pipeline 3** | DADA2 + RefSeq 16S (QIIME2) | SortMeRNA → Kraken2 + Bracken | RefSeq 16S |

> [!NOTE]
> **Pipeline 1** uses GreenGenes2 on both sides (GG2 classifier for 16S; WoLr2/GG2 taxonomy for MGS).
> **Pipelines 2 and 3** use RefSeq on both sides and **share the same 16S output** — the RefSeq 16S V4 classifier is applied to Pipeline 1's DADA2 ASVs via `pipeline3_patrick_Snakefile`, producing `results/patrick/pipeline3/16S/otu_table_genus.tsv`. Pipeline 2 references this same file.

---

## Prerequisites

### 1. Input Files Required

For each dataset, you need **two sets of raw reads** and a **sample mapping CSV**:

```
DataSets/<DATASET>/
├── WGS_RAW/                        # Shotgun metagenomics reads
│   ├── <WGS_SRR>_1.fastq.gz
│   └── <WGS_SRR>_2.fastq.gz
├── 16S_RAW/                        # 16S amplicon reads
│   ├── <16S_SRR>_1.fastq.gz
│   └── <16S_SRR>_2.fastq.gz
└── 16S_WGS_sample_name_mappings.csv
```

### 2. Mapping CSV Format

Three columns, **no header**, comma-separated:

```
WGS_SRR,16S_SRR,SAMPLE_NAME
SRR22438258,SRR22438216,BCH-F014
SRR22438257,SRR22438215,BCH-F015
...
```

For Patrick: **107 samples** (`BCH-F*` and `BCH-h*` naming).

### 3. Conda Environments & Modules

| Tool | Environment / Module |
|---|---|
| Woltka | `conda activate woltka` |
| QIIME2 | `conda activate qiime2-amplicon-2024.5` |
| SortMeRNA | `conda activate sortmerna` |
| Kraken2 + Bracken | `module load kraken/2.17.1` |
| Snakemake | `module load python` (within qiime2 env) |

### 4. Reference Databases

| Database | Path |
|---|---|
| WoLr2 (Bowtie2 index) | `/DCEG/Projects/Microbiome/Combined_Study/vol2/bowtie2/WoLr2/WoLr2` |
| GreenGenes2 taxonomy TSV | `/DCEG/Projects/Microbiome/Combined_Study/gg2_refs/taxonomy.tsv` |
| GG2 NB classifier (V4) | `/DCEG/Projects/Microbiome/Metagenomics/Combined_Study/16S/2024.09.backbone.v4.nb.qza` |
| Kraken2 standard DB | `/DCEG/Projects/Microbiome/Metagenomics/Kraken/kraken2/k2_standard_20240112` |
| SortMeRNA rRNA DB | `databases/sortmerna_rRNA/smr_v4.3_default_db.fasta` |
| RefSeq 16S V4 classifier | `/DCEG/Projects/Microbiome/Combined_Study/RefSeq-16S/refseq16s_V4_nb.qza` |

---

## Step-by-Step Processing

### All pipelines can be run in parallel — they are independent.

---

## Pipeline 1: Bowtie2 → Woltka → GreenGenes2

### MGS Side

#### Step 1 — Bowtie2 alignment (cluster, per-sample parallel)

```bash
bash submit_bowtie2_patrick.sh
```

- Submits one `sbatch` job per sample (`bt2_<SAMPLE>`)
- Each job: 80 GB RAM, 8 CPUs, up to 3 days
- **Output**: `results/patrick/pipeline1/MGS/alignments/<SAMPLE>.sam`
- **Check completion**: `ls results/patrick/pipeline1/MGS/alignments/*.sam | wc -l` → expect 107

#### Step 2 — Woltka classification + QIIME2 export (cluster, parallel batches)

> [!IMPORTANT]
> Woltka processes SAMs sequentially within one job. This script splits 107 SAMs into 10 batches and runs them simultaneously, then merges results in a dependency job.

```bash
bash submit_woltka_patrick.sh          # default: 10 batches
# or
bash submit_woltka_patrick.sh 15       # custom batch count
```

- Submits 10 `woltka_pat_b*` batch jobs → then `woltka_pat_merge` (auto-dependency)
- Merge job also runs full QIIME2 genus collapse + TSV export
- **Output**:
  - `results/patrick/pipeline1/MGS/woltka_out.biom`
  - `results/patrick/pipeline1/MGS/otu_table_genus.tsv`
  - `results/patrick/pipeline1/MGS/otu_table_full.tsv`

### 16S Side

#### Step 3 — DADA2 denoising + GreenGenes2 classification (Snakemake)

```bash
conda activate qiime2-amplicon-2024.5
module load python
snakemake -s pipeline1_patrick_Snakefile --cores 8
```

- Reads mapping CSV to find 16S SRR accessions
- Runs: manifest → QIIME2 import → DADA2 → GG2 classify → genus collapse → TSV export
- **Output**: `results/patrick/pipeline1/16S/otu_table_genus.tsv`

> [!NOTE]
> Pipeline 3's 16S side **reuses** the DADA2 ASV table and representative sequences from this step. Run Pipeline 1's 16S side before Pipeline 3's 16S side.

---

## Pipeline 2: Kraken2 → Bracken (full WGS reads)

### MGS Side

#### Step 1 — Kraken2 classification (cluster, per-sample parallel)

```bash
bash submit_kraken2_p2_patrick.sh
```

- Submits one `sbatch` job per sample (`k2p2_<SAMPLE>`)
- Each job: 100 GB RAM, 8 CPUs (Kraken2 standard DB is large)
- **Output**: `results/patrick/pipeline2/MGS/kraken2/<SAMPLE>.kraken` + `.kreport`
- **Check completion**: `ls results/patrick/pipeline2/MGS/kraken2/*.kreport | wc -l` → expect 107

#### Step 2 — Bracken re-estimation + combine table (interactive or login node)

```bash
module load kraken/2.17.1
bash process_bracken_p2_patrick.sh
```

- Runs Bracken on all 107 `.kreport` files sequentially (fast, ~seconds per sample)
- Combines all sample outputs into one genus table using an embedded Python script
- **Output**:
  - `results/patrick/pipeline2/MGS/bracken/<SAMPLE>_genus.bracken`
  - `results/patrick/pipeline2/MGS/otu_table_genus.tsv`

### 16S Side

Pipeline 2 uses the **same 16S output as Pipeline 3** (RefSeq 16S V4 classifier, not GG2):
`results/patrick/pipeline3/16S/otu_table_genus.tsv`

This is produced by `pipeline3_patrick_Snakefile` — run it before comparing Pipeline 2 results. See Pipeline 3 → 16S Side below.

---

## Pipeline 3: SortMeRNA → Kraken2 → Bracken (extracted 16S reads)

### MGS Side

#### Step 1 — Extract 16S reads with SortMeRNA (cluster, per-sample parallel)

```bash
bash submit_sortmerna_patrick.sh
```

- Submits one `sbatch` job per sample (`smr_<SAMPLE>`)
- Each job: 32 GB RAM, 8 CPUs, up to 1.5 days
- Extracts rRNA-matching reads from WGS data using the SortMeRNA v4.3 default rRNA database
- **Output** (per sample in `results/patrick/pipeline3/MGS/sortmerna/`):
  - `<SAMPLE>_16S_fwd.fq.gz` / `<SAMPLE>_16S_rev.fq.gz` (16S-matching reads)
  - `<SAMPLE>_non16S_fwd.fq.gz` / `<SAMPLE>_non16S_rev.fq.gz`
  - `<SAMPLE>_16S.log`
- **Check completion**: `ls results/patrick/pipeline3/MGS/sortmerna/*_16S_fwd.fq.gz | wc -l` → expect 107

#### Step 2 — Kraken2 on extracted 16S reads (cluster, per-sample parallel)

```bash
bash submit_kraken2_p3_patrick.sh
```

- Submits one `sbatch` job per sample (`k2p3_<SAMPLE>`)
- Each job: 100 GB RAM, 8 CPUs
- Classifies the extracted `*_16S_fwd/rev.fq.gz` reads against Kraken2 standard DB
- **Output**: `results/patrick/pipeline3/MGS/kraken2/<SAMPLE>.kraken` + `.kreport`
- **Check completion**: `ls results/patrick/pipeline3/MGS/kraken2/*.kreport | wc -l` → expect 107

#### Step 3 — Bracken re-estimation + combine table (interactive or login node)

```bash
module load kraken/2.17.1
bash process_bracken_p3_patrick.sh
```

- Same approach as Pipeline 2 Bracken step, but using P3 kreports
- **Output**:
  - `results/patrick/pipeline3/MGS/bracken/<SAMPLE>_genus.bracken`
  - `results/patrick/pipeline3/MGS/otu_table_genus.tsv`

### 16S Side

#### Step 4 — RefSeq 16S classification of ASVs (Snakemake)

> [!IMPORTANT]
> Requires Pipeline 1's DADA2 outputs to exist first:
> `results/patrick/pipeline1/16S/dada2_table.qza` and `rep_seqs.qza`

```bash
conda activate qiime2-amplicon-2024.5
module load python
snakemake -s pipeline3_patrick_Snakefile --cores 8
```

- Reclassifies the **same DADA2 ASVs** from Pipeline 1 using the RefSeq 16S V4 NB classifier
- **Output**: `results/patrick/pipeline3/16S/otu_table_genus.tsv`

---

## Expected Final Outputs

```
results/patrick/
├── pipeline1/
│   ├── 16S/
│   │   └── otu_table_genus.tsv      ← 16S x GG2 genus table
│   └── MGS/
│       ├── woltka_out.biom
│       ├── otu_table_genus.tsv      ← MGS x GG2 genus table
│       └── otu_table_full.tsv
├── pipeline2/
│   └── MGS/
│       ├── kraken2/                 ← per-sample .kraken + .kreport
│       ├── bracken/                 ← per-sample _genus.bracken
│       └── otu_table_genus.tsv     ← MGS x genus table (Kraken2/Bracken)
│   (16S → shared from pipeline3/16S/otu_table_genus.tsv)
└── pipeline3/
    ├── 16S/
    │   └── otu_table_genus.tsv      ← 16S x RefSeq genus table
    │                                   (shared by Pipeline 2 AND Pipeline 3)
    └── MGS/
        ├── sortmerna/               ← extracted 16S reads per sample
        ├── kraken2/                 ← per-sample .kraken + .kreport
        ├── bracken/                 ← per-sample _genus.bracken
        └── otu_table_genus.tsv     ← MGS x genus table (extracted 16S + Bracken)
```

---

## Full Run Order (with dependencies)

```
P1 MGS:  submit_bowtie2_patrick.sh
              ↓ (wait for all bt2_* jobs)
         submit_woltka_patrick.sh          ← auto-chains merge+QIIME2

P1 16S:  snakemake -s pipeline1_patrick_Snakefile
              ↓ (required by P3 16S)
P3 16S:  snakemake -s pipeline3_patrick_Snakefile

P2 MGS:  submit_kraken2_p2_patrick.sh
              ↓ (wait for all k2p2_* jobs)
         process_bracken_p2_patrick.sh

P3 MGS:  submit_sortmerna_patrick.sh
              ↓ (wait for all smr_* jobs)
         submit_kraken2_p3_patrick.sh
              ↓ (wait for all k2p3_* jobs)
         process_bracken_p3_patrick.sh
```

> [!TIP]
> P1 MGS, P2 MGS, and P3 MGS can all be **submitted at the same time**. P1 16S and P3 16S can also be started as soon as raw data is available (P3 16S must wait for P1 16S to finish).

---

## Adapting for a New Dataset

To run a new dataset through all three pipelines:

1. **Download reads** into `DataSets/<NEW_DATASET>/WGS_RAW/` and `16S_RAW/`

2. **Create a mapping CSV** at `DataSets/<NEW_DATASET>/16S_WGS_sample_name_mappings.csv`:
   ```
   <WGS_SRR>,<16S_SRR>,<SAMPLE_NAME>
   ```

3. **Copy the Patrick scripts** and update two paths in each:
   - `DATA_DIR` / `MAPPING_CSV` → point to new dataset
   - `OUT_DIR` → change `results/patrick/` → `results/<new_dataset>/`

4. **Scripts to copy and update**:

   | Script | Path variables to update |
   |---|---|
   | `submit_bowtie2_<new>.sh` | `DATA_DIR`, `MAPPING_CSV`, `OUT_DIR`, `LOG_DIR` |
   | `submit_woltka_<new>.sh` | `SAM_DIR`, `OUT_DIR`, `LOG_DIR`, `BATCH_BASE` |
   | `submit_kraken2_p2_<new>.sh` | `DATA_DIR`, `MAPPING_CSV`, `OUT_DIR`, `LOG_DIR` |
   | `process_bracken_p2_<new>.sh` | `MAPPING_CSV`, `K2_DIR`, `BR_DIR`, `OUT_DIR` |
   | `submit_sortmerna_<new>.sh` | `DATA_DIR`, `MAPPING_CSV`, `OUT_DIR`, `LOG_DIR` |
   | `submit_kraken2_p3_<new>.sh` | `MAPPING_CSV`, `SMR_DIR`, `K2_DIR`, `LOG_DIR` |
   | `process_bracken_p3_<new>.sh` | `MAPPING_CSV`, `K2_DIR`, `BR_DIR`, `OUT_DIR` |
   | `pipeline1_<new>_Snakefile` | `DATA_DIR`, `MAPPING_CSV`, `OUT_BASE` |
   | `pipeline3_<new>_Snakefile` | `P1_16S`, `P3_16S` (output paths) |

5. **Run in the order shown above**.

---

## Quick Status Check

```bash
# Check running jobs
squeue -u $USER

# Check output counts (replace 'patrick' with dataset name)
echo "P1 SAMs:      $(ls results/patrick/pipeline1/MGS/alignments/*.sam 2>/dev/null | wc -l)/107"
echo "P2 kreports:  $(ls results/patrick/pipeline2/MGS/kraken2/*.kreport 2>/dev/null | wc -l)/107"
echo "P3 sortmerna: $(ls results/patrick/pipeline3/MGS/sortmerna/*_16S_fwd.fq.gz 2>/dev/null | wc -l)/107"
echo "P3 kreports:  $(ls results/patrick/pipeline3/MGS/kraken2/*.kreport 2>/dev/null | wc -l)/107"

# Check final outputs
ls results/patrick/pipeline1/MGS/otu_table_genus.tsv 2>/dev/null && echo "P1 MGS done" || echo "P1 MGS pending"
ls results/patrick/pipeline2/MGS/otu_table_genus.tsv 2>/dev/null && echo "P2 MGS done" || echo "P2 MGS pending"
ls results/patrick/pipeline3/MGS/otu_table_genus.tsv 2>/dev/null && echo "P3 MGS done" || echo "P3 MGS pending"
ls results/patrick/pipeline1/16S/otu_table_genus.tsv 2>/dev/null && echo "P1 16S done" || echo "P1 16S pending"
ls results/patrick/pipeline3/16S/otu_table_genus.tsv 2>/dev/null && echo "P3 16S done" || echo "P3 16S pending"
```
