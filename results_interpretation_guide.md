# 16S vs WGS PDF Results Interpretation Guide

This guide explains how to interpret the generated overview PDFs that compare 16S and shotgun metagenomics profiles.

## Purpose

Use the PDF to answer three questions:

1. How similar are 16S and WGS for the same samples?
2. Where do they systematically disagree?
3. Are differences small enough for your downstream biological question?

## Recommended Reading Order

1. **Check depth context first** (`Mapping.csv`): look for major imbalance between `WGS_count` and `16S_count`.
2. **Taxon-level panel**: inspect log-fold change and enriched taxa lists.
3. **Sample-level agreement metrics**: Spearman, Pearson, L1.
4. **Diversity panels**: Shannon and richness bias/RMSE.
5. **Ordination + PERMANOVA**: evaluate method-level global separation.
6. **Final judgment**: decide if methods are interchangeable for your use case.

## Panel-by-Panel Interpretation

## 1) LFC / abundance panel

- Shows taxa enriched in 16S vs enriched in WGS.
- Persistent directional shifts suggest method bias rather than random variation.
- Focus on repeatedly enriched taxa across pipelines.

## 2) Top enriched taxa lists

- Identifies taxa driving disagreement.
- Use these lists for QC and biological plausibility checks.

## 3) Shared taxa and agreement metrics

- **Spearman**: rank-order agreement.
- **Pearson**: linear agreement (sensitive to high-abundance taxa).
- **L1**: total abundance disagreement (distance, not correlation; lower is better).

## 4) Diversity panels

- **Shannon bias** = mean(Shannon_16S - Shannon_WGS): captures direction.
- **Shannon RMSE**: magnitude of disagreement (no direction).
- Same interpretation for richness bias/RMSE.

## 5) PCoA + PERMANOVA

- **PERMANOVA R²**: variance explained by method.
- **PERMANOVA p**: statistical significance of method separation.
- Even moderate R² can be important if doing differential-abundance or biomarker analyses.

## Metric Heuristics (Practical)

- **Spearman**:
  - `>= 0.7` strong
  - `0.4–0.7` moderate
  - `< 0.4` weak
- **L1**: lower is better; compare across runs, not as a universal absolute cutoff.
- **Bias near 0 + low RMSE**: stronger cross-method consistency.
- **Significant PERMANOVA + non-trivial R²**: method likely affects biological interpretation.

## Decision Patterns

### Pattern A
High Spearman/Pearson + low L1 + low PERMANOVA R²  
**Interpretation:** strong method concordance.

### Pattern B
Moderate correlations + directional enriched taxa  
**Interpretation:** systematic method bias in specific clades.

### Pattern C
Large richness bias but modest Shannon bias  
**Interpretation:** detection-threshold/depth effects more than major community-structure shift.

### Pattern D
Significant PERMANOVA with meaningful R²  
**Interpretation:** method changes multivariate conclusions; consider method-stratified analyses.

## Common Pitfalls

1. Interpreting species-level agreement too literally across modalities.
2. Ignoring depth asymmetry in `Mapping.csv`.
3. Treating p-values as effect size (always pair p with R² and practical impact).
4. Concluding equivalence from one metric only.
5. Ignoring method-sensitive taxa when reporting biology.


## Minimal QC Checklist

- Same taxonomy release/rank harmonization across methods.
- Paired sample IDs correctly matched.
- Depth imbalance checked before interpreting unique taxa.
- Thresholds documented (prevalence, abundance, confidence).
- Method-sensitive taxa reviewed before final conclusions.

