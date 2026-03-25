# 16S and Shotgun Metagenomics Data Integration

This repository organizes a unified framework to compare **16S amplicon** and **shotgun metagenomics (SM/WGS)** profiles using a harmonized taxonomy strategy, with emphasis on reproducible cross-method concordance analysis.

## Project Goals

1. Process 16S and shotgun data with comparable taxonomic labels.
2. Quantify agreement and disagreement between methods at genus/species level.
3. Generate interpretable summary reports for method benchmarking.
4. Transition to a GTDB-centered integration workflow for improved harmonization.

## Current Analysis Context

The active comparison workflow uses three 16S-vs-WGS pipelines and produces:

- per-pipeline overview PDFs
- a combined comparison PDF
- an interactive merged HTML report
- a consolidated stats table (`combined_stats.tsv`)

Core metrics used in interpretation:

- **Spearman / Pearson**: cross-method concordance
- **L1 distance**: magnitude of abundance disagreement
- **Shared vs unique taxa** (`n_common_taxa`, `n_unique_wgs`, `n_unique_16S`)
- **Shannon / richness bias and RMSE**
- **PERMANOVA R² and p-value** for method effect in community composition

## How to Interpret the Reports

### Agreement panel

- Higher Spearman/Pearson and lower L1 indicate better 16S-vs-WGS alignment.
- L1 is a distance (not a correlation): lower values are better.

### Shared/unique taxa panel

- `n_common_taxa`: taxa detected by both methods.
- `n_unique_wgs` / `n_unique_16S`: method-specific detections.
- Always interpret unique taxa alongside read-depth balance (`Mapping.csv`: `WGS_count` vs `16S_count`).

### Diversity panels

- **Shannon bias** = mean(Shannon_16S - Shannon_WGS): captures direction.
- **Shannon RMSE**: captures disagreement magnitude, not direction.
- Same logic applies to richness bias/RMSE.

### Ordination / PERMANOVA panel

- Significant p-values with non-trivial R² indicate method contributes to composition differences.
- Even modest R² can be relevant for downstream differential-abundance studies.

## GTDB-Integrated Future Workflow

The long-term workflow is documented in:

- `gtdb_integrated_pipeline.md`

That roadmap includes:

1. **16S GTDB-aligned classification**
- QIIME2 + RESCRIPt classifier training
- SILVA sequence handling with GTDB taxonomy remapping
- primer-region extraction and Naive Bayes classification

2. **Shotgun GTDB profiling**
- Kraken2/Bracken with GTDB-based databases (prebuilt or Struo2-built)
- optional MetaPhlAn4-compatible strategy

3. **Taxonomy harmonization and table merging (R)**
- collapse both modalities to common rank (typically genus)
- harmonize labels (`g__` cleanup, naming normalization)
- compute shared-only and full-union comparisons

4. **Compositional normalization and concordance analysis**
- CLR transforms with pseudocount
- per-taxon Spearman concordance
- sample-level agreement summaries and visualization

## Recommended Next Analyses

1. Pin and document one GTDB release (versioned metadata in outputs).
2. Add threshold sensitivity checks (prevalence, abundance, confidence).
3. Add optional DA benchmarking (ALDEx2/ANCOM-BC) with truth-aware metrics for simulated/spike-in data.
4. Track persistent method-sensitive taxa across pipelines.
5. Export self-contained report bundles for external collaborators.

## Reproducibility Notes

- Keep configuration files under version control.
- Record software/database versions for every run.
- Preserve portable report bundles (`html + assets + pdf + stats`) for sharing.
