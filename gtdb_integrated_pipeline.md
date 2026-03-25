# GTDB-based integrated 16S + shotgun pipeline
## Commands and concordance analysis

---

## Part 1 — Build the GTDB-trained 16S classifier (QIIME2 RESCRIPt)

### 1.1 Install dependencies

```bash
conda create -n qiime2-rescript -c qiime2 -c conda-forge -c bioconda \
  qiime2 q2-rescript q2-feature-classifier
conda activate qiime2-rescript
```

### 1.2 Fetch SILVA sequences and import GTDB taxonomy mapping

SILVA 138 sequences with GTDB r214 taxonomy remapping (maintained by the
RESCRIPt community — download the pre-built mapping from the QIIME2 forum
resources, or generate it from the GTDB-SILVA mapping table).

```bash
# Download GTDB r214 taxonomy files (bacteria + archaea)
# These are the correct flat-file releases — gtdbtk_v2_data is NOT available for r214
wget https://data.gtdb.ecogenomic.org/releases/release214/214.1/bac120_taxonomy_r214.tsv.gz
wget https://data.gtdb.ecogenomic.org/releases/release214/214.1/ar53_taxonomy_r214.tsv.gz
gunzip bac120_taxonomy_r214.tsv.gz ar53_taxonomy_r214.tsv.gz

# Concatenate into a single GTDB taxonomy file
cat bac120_taxonomy_r214.tsv ar53_taxonomy_r214.tsv > gtdb_r214_taxonomy.tsv

# Download the GTDB-to-SILVA accession mapping (maps SILVA accessions to GTDB lineages)
# Maintained by the RESCRIPt team alongside the GTDB r214 release:
wget https://data.gtdb.ecogenomic.org/releases/release214/214.1/auxillary_files/gtdbtk_r214_data.tar.gz
# If the above is unavailable, use the community-maintained mapping on the QIIME2 forum:
# https://forum.qiime2.org/t/gtdb-r214-silva-138-mapping/

# Fetch SILVA 138 SSURef NR99 sequences via RESCRIPt
qiime rescript get-silva-data \
  --p-version '138.1' \
  --p-target 'SSURef_NR99' \
  --p-include-species-labels \
  --o-silva-sequences silva-138-ssu-nr99-seqs.qza \
  --o-silva-taxonomy silva-138-ssu-nr99-tax.qza

# Cull sequences by length and ambiguity (removes low-quality entries)
qiime rescript cull-seqs \
  --i-sequences silva-138-ssu-nr99-seqs.qza \
  --o-clean-sequences silva-138-ssu-nr99-seqs-cleaned.qza

# Filter to 16S only (remove 18S/ITS)
qiime rescript filter-seqs-length-by-taxon \
  --i-sequences silva-138-ssu-nr99-seqs-cleaned.qza \
  --i-taxonomy silva-138-ssu-nr99-tax.qza \
  --p-labels Archaea Bacteria \
  --p-min-lens 900 900 \
  --o-filtered-seqs silva-138-16S-filtered.qza \
  --o-discarded-seqs silva-138-discarded.qza
```

### 1.3 Remap SILVA taxonomy to GTDB

```bash
# Replace SILVA taxonomy strings with GTDB lineage strings
# using the GTDB-SILVA mapping file (tab-separated: SILVA_accession <tab> GTDB_lineage)
qiime rescript edit-taxonomy \
  --i-taxonomy silva-138-ssu-nr99-tax.qza \
  --m-taxonomy-map-file gtdb_silva138_mapping.tsv \
  --o-edited-taxonomy silva-138-gtdb-tax.qza
```

> **Note:** Pre-built GTDB-remapped SILVA classifiers for V3-V4 (341F/806R)
> and V4 (515F/806R) are available from the QIIME2 community resources page.
> Use those if your primer pair matches — they save hours of build time.

### 1.4 Extract amplicon region and train classifier

```bash
# Trim to your amplicon region — edit primers to match your protocol
# Example: V4 region (515F / 806R)
qiime feature-classifier extract-reads \
  --i-sequences silva-138-16S-filtered.qza \
  --p-f-primer GTGYCAGCMGCCGCGGTAA \
  --p-r-primer GGACTACNVGGGTWTCTAAT \
  --p-min-length 100 \
  --p-max-length 400 \
  --o-reads silva-138-gtdb-v4-seqs.qza

# Dereplicate extracted reads
qiime rescript dereplicate \
  --i-sequences silva-138-gtdb-v4-seqs.qza \
  --i-taxa silva-138-gtdb-tax.qza \
  --p-rank-handles 'silva' \
  --p-mode 'uniq' \
  --o-dereplicated-sequences silva-138-gtdb-v4-derep.qza \
  --o-dereplicated-taxa silva-138-gtdb-v4-derep-tax.qza

# Train the Naive Bayes classifier
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads silva-138-gtdb-v4-derep.qza \
  --i-reference-taxonomy silva-138-gtdb-v4-derep-tax.qza \
  --o-classifier silva-138-gtdb-v4-classifier.qza

echo "Classifier ready: silva-138-gtdb-v4-classifier.qza"
```

### 1.5 Classify your 16S ASVs

```bash
qiime feature-classifier classify-sklearn \
  --i-classifier silva-138-gtdb-v4-classifier.qza \
  --i-reads rep-seqs.qza \
  --p-confidence 0.8 \
  --p-n-jobs -1 \
  --o-classification taxonomy-gtdb.qza

# Export to TSV for downstream R/Python work
qiime tools export --input-path taxonomy-gtdb.qza --output-path taxonomy-gtdb/
qiime tools export --input-path table.qza --output-path feature-table/
```

---

## Part 2 — Build the Kraken2/Bracken GTDB database (shotgun)

### 2.1 Option A — Use pre-built index (recommended)

Pre-built GTDB r214 Kraken2 indexes are maintained by the Struo2 pipeline.
Download from: https://portal.nersc.gov/genomicscm/tuba/

```bash
# Download GTDB r214 Kraken2 + Bracken database (~70 GB uncompressed)
wget https://portal.nersc.gov/genomicscm/tuba/gtdb_r214_k2.tar.gz
tar -xzf gtdb_r214_k2.tar.gz -C /databases/kraken2_gtdb/

# Build Bracken database for your read length (e.g. 150 bp)
bracken-build \
  -d /databases/kraken2_gtdb/ \
  -t 16 \
  -l 150
```

### 2.2 Option B — Build from scratch with Struo2

```bash
# Clone Struo2
git clone https://github.com/nick-youngblut/GTDB_Kraken.git
cd GTDB_Kraken

# Download GTDB genome metadata
wget https://data.gtdb.ecogenomic.org/releases/release214/214.1/bac120_metadata_r214.tar.gz
wget https://data.gtdb.ecogenomic.org/releases/release214/214.1/ar53_metadata_r214.tar.gz

# Configure and run (requires ~500 GB scratch space, 32+ cores, several days)
snakemake --use-conda --cores 32 -s Snakefile
```

### 2.3 Classify shotgun reads with Kraken2 + Bracken

```bash
# Per-sample classification loop
for SAMPLE in $(cat samples.txt); do
  kraken2 \
    --db /databases/kraken2_gtdb/ \
    --threads 16 \
    --paired \
    --gzip-compressed \
    --output ${SAMPLE}.kraken2.out \
    --report ${SAMPLE}.kraken2.report \
    ${SAMPLE}_R1.fastq.gz ${SAMPLE}_R2.fastq.gz

  # Re-estimate abundances at species level
  bracken \
    -d /databases/kraken2_gtdb/ \
    -i ${SAMPLE}.kraken2.report \
    -o ${SAMPLE}.bracken \
    -r 150 \
    -l S \
    -t 10
done

# Combine all samples into one table
python combine_bracken_outputs.py \
  --files *.bracken \
  --output bracken_combined_species.tsv
```

### 2.4 Alternative — MetaPhlAn4 with GTDB-compatible SGB database

```bash
# Download the GTDB-compatible marker database
metaphlan --install --bowtie2db /databases/metaphlan4/ \
  --index mpa_vJan21_CHOCOPhlAnSGB_202103

# Run per sample
for SAMPLE in $(cat samples.txt); do
  metaphlan \
    ${SAMPLE}_R1.fastq.gz,${SAMPLE}_R2.fastq.gz \
    --input_type fastq \
    --bowtie2db /databases/metaphlan4/ \
    --nproc 16 \
    --output_file ${SAMPLE}_metaphlan.tsv
done

# Merge all samples
merge_metaphlan_tables.py *_metaphlan.tsv > metaphlan_merged.tsv
```

---

## Part 3 — Taxonomy harmonization and table merging (R)

```r
library(tidyverse)
library(phyloseq)
library(vegan)

# ── Load 16S feature table and taxonomy ──────────────────────────────────────
asv_counts <- read_tsv("feature-table/feature-table.tsv", skip=1)
tax_16s    <- read_tsv("taxonomy-gtdb/taxonomy.tsv") %>%
  separate(Taxon, into = c("domain","phylum","class","order",
                           "family","genus","species"),
           sep = ";", fill = "right") %>%
  mutate(across(domain:species, str_trim))

# ── Load shotgun Bracken table ────────────────────────────────────────────────
shotgun <- read_tsv("bracken_combined_species.tsv") %>%
  rename_with(~ str_remove(., "_num$|_frac$"))

# ── Collapse 16S to genus level ───────────────────────────────────────────────
asv_genus <- asv_counts %>%
  left_join(tax_16s %>% select(Feature.ID, genus), by = "Feature.ID") %>%
  group_by(genus) %>%
  summarise(across(where(is.numeric), sum)) %>%
  filter(!is.na(genus), genus != "g__")

# ── Collapse shotgun to genus level ───────────────────────────────────────────
# Extract genus from GTDB lineage string (6th field, "g__..." prefix)
shotgun_genus <- shotgun %>%
  mutate(genus = str_extract(name, "g__[^;]+")) %>%
  group_by(genus) %>%
  summarise(across(where(is.numeric), sum)) %>%
  filter(!is.na(genus))

# ── Harmonize genus labels (strip "g__" prefix, lowercase) ───────────────────
clean_genus <- function(df) {
  df %>% mutate(genus = str_remove(genus, "^g__") %>% str_to_sentence())
}
asv_genus     <- clean_genus(asv_genus)
shotgun_genus <- clean_genus(shotgun_genus)

# ── Find shared taxa ──────────────────────────────────────────────────────────
shared_taxa <- intersect(asv_genus$genus, shotgun_genus$genus)
cat("Shared genera:", length(shared_taxa), "\n")
cat("16S only:", nrow(asv_genus) - length(shared_taxa), "\n")
cat("Shotgun only:", nrow(shotgun_genus) - length(shared_taxa), "\n")

# ── CLR normalization (both tables) ──────────────────────────────────────────
clr_transform <- function(mat) {
  # Add pseudocount, then CLR
  mat <- mat + 0.5
  log(mat) - rowMeans(log(mat))
}

mat_16s     <- asv_genus %>%
  filter(genus %in% shared_taxa) %>%
  column_to_rownames("genus") %>% as.matrix() %>% t()

mat_shotgun <- shotgun_genus %>%
  filter(genus %in% shared_taxa) %>%
  column_to_rownames("genus") %>% as.matrix() %>% t()

clr_16s     <- clr_transform(mat_16s)
clr_shotgun <- clr_transform(mat_shotgun)
```

---

## Part 4 — Concordance analysis (R)

### 4.1 Per-taxon Spearman correlation across samples

```r
library(ggplot2)
library(ggrepel)

# Samples must be in the same order in both matrices
stopifnot(rownames(clr_16s) == rownames(clr_shotgun))

concordance <- map_dfr(shared_taxa, function(g) {
  x <- clr_16s[, g]
  y <- clr_shotgun[, g]
  ct <- cor.test(x, y, method = "spearman")
  tibble(
    genus      = g,
    rho        = ct$estimate,
    p_value    = ct$p.value,
    mean_abund = mean(c(x, y))
  )
}) %>%
  mutate(
    p_adj      = p.adjust(p_value, method = "BH"),
    concordant = p_adj < 0.05 & rho > 0.6
  )

# Volcano-style concordance plot
ggplot(concordance, aes(x = rho, y = -log10(p_adj), color = concordant)) +
  geom_point(aes(size = mean_abund), alpha = 0.7) +
  geom_text_repel(
    data = filter(concordance, concordant | rho < 0.2),
    aes(label = genus), size = 3
  ) +
  geom_vline(xintercept = 0.6, linetype = "dashed", color = "gray50") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("FALSE" = "#B4B2A9", "TRUE" = "#1D9E75")) +
  labs(
    x = "Spearman rho (16S vs shotgun)",
    y = "-log10 adjusted p-value",
    title = "Cross-method concordance per genus",
    color = "Concordant"
  ) +
  theme_minimal()

ggsave("concordance_volcano.pdf", width = 8, height = 6)
```

### 4.2 Bland-Altman plot (bias across abundance range)

```r
# For each sample-genus pair, compute mean and difference of CLR values
ba_data <- map_dfr(shared_taxa, function(g) {
  tibble(
    genus = g,
    sample = rownames(clr_16s),
    mean_clr = (clr_16s[, g] + clr_shotgun[, g]) / 2,
    diff_clr = clr_16s[, g] - clr_shotgun[, g]
  )
})

bias      <- mean(ba_data$diff_clr)
loa_upper <- bias + 1.96 * sd(ba_data$diff_clr)
loa_lower <- bias - 1.96 * sd(ba_data$diff_clr)

ggplot(ba_data, aes(x = mean_clr, y = diff_clr)) +
  geom_point(alpha = 0.3, size = 1.2, color = "#378ADD") +
  geom_hline(yintercept = bias,     color = "#D85A30", linewidth = 0.8) +
  geom_hline(yintercept = loa_upper, linetype = "dashed", color = "#D85A30") +
  geom_hline(yintercept = loa_lower, linetype = "dashed", color = "#D85A30") +
  annotate("text", x = Inf, y = bias,
           label = sprintf("Bias = %.2f", bias),
           hjust = 1.1, vjust = -0.5, size = 3) +
  labs(
    x = "Mean CLR (16S + shotgun) / 2",
    y = "Difference CLR (16S − shotgun)",
    title = "Bland-Altman: 16S vs shotgun CLR abundance"
  ) +
  theme_minimal()

ggsave("bland_altman.pdf", width = 8, height = 5)
```

### 4.3 Differential abundance concordance (ALDEx2)

```r
library(ALDEx2)

# Run ALDEx2 on 16S genus table
# 'conds' is a character vector of group labels per sample
da_16s <- aldex(
  reads   = t(mat_16s),      # ALDEx2 expects taxa as rows
  conditions = conds,
  mc.samples = 128,
  test = "t",
  effect = TRUE,
  denom = "all"
) %>%
  rownames_to_column("genus") %>%
  select(genus, effect_16s = effect, we.eBH_16s = we.eBH)

# Run ALDEx2 on shotgun genus table
da_shotgun <- aldex(
  reads   = t(mat_shotgun),
  conditions = conds,
  mc.samples = 128,
  test = "t",
  effect = TRUE,
  denom = "all"
) %>%
  rownames_to_column("genus") %>%
  select(genus, effect_shotgun = effect, we.eBH_shotgun = we.eBH)

# Join and classify concordance
da_compare <- inner_join(da_16s, da_shotgun, by = "genus") %>%
  mutate(
    sig_16s     = we.eBH_16s < 0.05,
    sig_shotgun = we.eBH_shotgun < 0.05,
    concordance = case_when(
      sig_16s & sig_shotgun &
        sign(effect_16s) == sign(effect_shotgun) ~ "concordant",
      sig_16s & !sig_shotgun                     ~ "16S only",
      !sig_16s & sig_shotgun                     ~ "shotgun only",
      TRUE                                       ~ "not significant"
    )
  )

# Effect size correlation plot
ggplot(da_compare, aes(x = effect_16s, y = effect_shotgun, color = concordance)) +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray60") +
  geom_text_repel(
    data = filter(da_compare, concordance == "concordant"),
    aes(label = genus), size = 3
  ) +
  scale_color_manual(values = c(
    "concordant"       = "#1D9E75",
    "16S only"         = "#3B8BD4",
    "shotgun only"     = "#7F77DD",
    "not significant"  = "#B4B2A9"
  )) +
  labs(
    x = "ALDEx2 effect size (16S)",
    y = "ALDEx2 effect size (shotgun)",
    title = "Differential abundance concordance",
    color = NULL
  ) +
  theme_minimal()

ggsave("da_concordance.pdf", width = 7, height = 6)

# Summary table
da_compare %>%
  count(concordance) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  print()
```

### 4.4 Beta-diversity concordance (Procrustes analysis)

```r
library(vegan)

# PCoA on CLR-transformed tables (Euclidean = Aitchison distance)
pco_16s     <- cmdscale(dist(clr_16s),     k = 2)
pco_shotgun <- cmdscale(dist(clr_shotgun), k = 2)

# Procrustes rotation: how well do the two ordinations align?
proc <- procrustes(pco_16s, pco_shotgun, symmetric = TRUE)
protest_result <- protest(pco_16s, pco_shotgun, permutations = 999)

cat("Procrustes M2 =", proc$ss, "\n")
cat("Protest p-value =", protest_result$signif, "\n")
# M2 close to 0 and p < 0.05 = ordinations are concordant

# Plot
proc_df <- as_tibble(proc$Yrot) %>%
  rename(x_rot = V1, y_rot = V2) %>%
  bind_cols(as_tibble(proc$X) %>% rename(x_16s = V1, y_16s = V2)) %>%
  mutate(sample = rownames(clr_16s))

ggplot(proc_df) +
  geom_segment(aes(x = x_16s, y = y_16s, xend = x_rot, yend = y_rot),
               color = "gray70", linewidth = 0.4) +
  geom_point(aes(x = x_16s,  y = y_16s),  color = "#1D9E75", size = 2.5) +
  geom_point(aes(x = x_rot,  y = y_rot),  color = "#7F77DD", size = 2.5) +
  labs(
    title = sprintf("Procrustes analysis (M2 = %.3f, p = %.3f)",
                    proc$ss, protest_result$signif),
    subtitle = "Green = 16S  |  Purple = shotgun (rotated)",
    x = "PC1", y = "PC2"
  ) +
  theme_minimal()

ggsave("procrustes.pdf", width = 7, height = 6)
```

---

## Part 5 — Summary: expected outputs and interpretation

| Analysis | Output | Interpretation |
|---|---|---|
| Spearman per taxon | rho distribution | rho > 0.6 for abundant taxa = methods agree |
| Bland-Altman | Bias ± LoA | Systematic bias flags primer or database mismatch |
| DA concordance | % concordant | >60% concordant = robust biological signal |
| Procrustes | M2, p-value | M2 < 0.2 and p < 0.05 = global community structure agrees |

**Key flags to investigate:**
- Taxa with low rho but high mean abundance → likely primer bias in 16S
- Systematic positive bias in 16S (Bland-Altman) → common for certain Firmicutes
- Taxa significant in shotgun only → likely below 16S detection threshold
- Taxa significant in 16S only → possibly misclassified in shotgun at species→genus collapse

---

## Software versions used

| Tool | Version | Install |
|---|---|---|
| QIIME2 | 2024.5 | `conda install -c qiime2` |
| RESCRIPt | 2024.5 | `pip install q2-rescript` |
| Kraken2 | 2.1.3 | `conda install -c bioconda kraken2` |
| Bracken | 2.9 | `conda install -c bioconda bracken` |
| MetaPhlAn4 | 4.1.0 | `conda install -c bioconda metaphlan` |
| ALDEx2 | 1.34 | `BiocManager::install("ALDEx2")` |
| vegan | 2.6 | `install.packages("vegan")` |
| taxonkit | 0.16 | `conda install -c bioconda taxonkit` |
