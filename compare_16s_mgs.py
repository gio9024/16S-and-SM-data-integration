#!/usr/bin/env python3
"""
Compare Pipeline 1 taxonomy results: 16S (DADA2 + GG2) vs MGS (Woltka + GG2)
Generates a markdown report: Zymo_Pipeline1_Comparison_Report.md
"""

import pandas as pd
import os
import sys
from datetime import datetime

PROJ = os.path.dirname(os.path.abspath(__file__))
FILE_16S = os.path.join(PROJ, "results/16S/otu_table_genus.tsv")
FILE_MGS = os.path.join(PROJ, "results/MGS/otu_table_genus.tsv")
REPORT   = os.path.join(PROJ, "Zymo_Pipeline1_Comparison_Report.md")


def load_genus_table(path, method_label):
    """Load a genus-level OTU table TSV, return tidy DataFrame."""
    df = pd.read_csv(path, sep="\t", index_col=0)
    # Clean up genus name: take last level of taxonomy string
    df.index.name = "Taxonomy"
    # Melt to long format
    long = df.reset_index().melt(id_vars="Taxonomy", var_name="SampleID", value_name="Count")
    long["Method"] = method_label
    return df, long


def extract_genus(tax_string):
    """Extract the genus name from a full GG2 taxonomy string."""
    parts = [p.strip() for p in tax_string.split(";")]
    for p in reversed(parts):
        if p.startswith("g__") and len(p) > 3:
            return p[3:]
    return tax_string  # fallback


def main():
    # --- Check files exist ---
    for f, label in [(FILE_16S, "16S"), (FILE_MGS, "MGS")]:
        if not os.path.exists(f):
            print(f"ERROR: {label} genus table not found: {f}")
            sys.exit(1)

    # --- Load data ---
    df_16s, long_16s = load_genus_table(FILE_16S, "16S")
    df_mgs, long_mgs = load_genus_table(FILE_MGS, "MGS")

    # --- Summary stats ---
    n_genera_16s = len(df_16s)
    n_genera_mgs = len(df_mgs)
    n_samples_16s = len(df_16s.columns)
    n_samples_mgs = len(df_mgs.columns)

    # --- Extract genus sets ---
    genera_16s = set(df_16s.index)
    genera_mgs = set(df_mgs.index)
    shared_genera = genera_16s & genera_mgs
    only_16s = genera_16s - genera_mgs
    only_mgs = genera_mgs - genera_16s

    # --- Top genera per method (by total counts across all samples) ---
    top_16s = df_16s.sum(axis=1).sort_values(ascending=False).head(20)
    top_mgs = df_mgs.sum(axis=1).sort_values(ascending=False).head(20)

    # --- Relative abundance ---
    ra_16s = df_16s.div(df_16s.sum(axis=0), axis=1) * 100
    ra_mgs = df_mgs.div(df_mgs.sum(axis=0), axis=1) * 100
    mean_ra_16s = ra_16s.mean(axis=1).sort_values(ascending=False)
    mean_ra_mgs = ra_mgs.mean(axis=1).sort_values(ascending=False)

    # --- Build report ---
    lines = []
    lines.append("# Zymo Pipeline 1 — 16S vs MGS Taxonomy Comparison Report")
    lines.append("")
    lines.append(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    lines.append(f"**Pipeline:** Greengenes2 + Woltka (MGS) / DADA2 + GG2 classifier (16S)")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Overview
    lines.append("## 1. Overview")
    lines.append("")
    lines.append("| Metric | 16S (DADA2 + GG2) | MGS (Woltka + GG2) |")
    lines.append("|--------|-------------------|---------------------|")
    lines.append(f"| Samples | {n_samples_16s} | {n_samples_mgs} |")
    lines.append(f"| Total genera detected | {n_genera_16s} | {n_genera_mgs} |")
    lines.append(f"| Total read counts | {int(df_16s.sum().sum()):,} | {int(df_mgs.sum().sum()):,} |")
    lines.append("")

    # Sample names
    lines.append("### Sample IDs")
    lines.append("")
    lines.append("**16S samples:**")
    for s in df_16s.columns:
        lines.append(f"- `{s}`")
    lines.append("")
    lines.append("**MGS samples:**")
    for s in df_mgs.columns:
        lines.append(f"- `{s}`")
    lines.append("")

    # Genus overlap
    lines.append("---")
    lines.append("")
    lines.append("## 2. Genus-Level Overlap")
    lines.append("")
    lines.append(f"| Category | Count |")
    lines.append(f"|----------|-------|")
    lines.append(f"| Shared genera (both methods) | {len(shared_genera)} |")
    lines.append(f"| Unique to 16S | {len(only_16s)} |")
    lines.append(f"| Unique to MGS | {len(only_mgs)} |")
    lines.append(f"| Total unique genera | {len(genera_16s | genera_mgs)} |")
    lines.append("")

    # Top 20 genera — 16S
    lines.append("---")
    lines.append("")
    lines.append("## 3. Top 20 Genera by Total Counts")
    lines.append("")
    lines.append("### 16S (DADA2 + GG2)")
    lines.append("")
    lines.append("| Rank | Genus | Total Counts | Mean Rel. Abundance (%) | Also in MGS? |")
    lines.append("|------|-------|-------------|------------------------|--------------|")
    for rank, (tax, count) in enumerate(top_16s.items(), 1):
        genus = extract_genus(tax)
        ra = mean_ra_16s.get(tax, 0)
        in_mgs = "✅" if tax in genera_mgs else "❌"
        lines.append(f"| {rank} | {genus} | {int(count):,} | {ra:.2f} | {in_mgs} |")
    lines.append("")

    # Top 20 genera — MGS
    lines.append("### MGS (Woltka + GG2)")
    lines.append("")
    lines.append("| Rank | Genus | Total Counts | Mean Rel. Abundance (%) | Also in 16S? |")
    lines.append("|------|-------|-------------|------------------------|--------------|")
    for rank, (tax, count) in enumerate(top_mgs.items(), 1):
        genus = extract_genus(tax)
        ra = mean_ra_mgs.get(tax, 0)
        in_16s = "✅" if tax in genera_16s else "❌"
        lines.append(f"| {rank} | {genus} | {int(count):,} | {ra:.2f} | {in_16s} |")
    lines.append("")

    # Shared genera comparison
    lines.append("---")
    lines.append("")
    lines.append("## 4. Shared Genera — Mean Relative Abundance Comparison")
    lines.append("")
    lines.append("Top shared genera ranked by average relative abundance across both methods:")
    lines.append("")
    lines.append("| Genus | 16S Mean RA (%) | MGS Mean RA (%) | Ratio (MGS/16S) |")
    lines.append("|-------|----------------|----------------|-----------------|")

    shared_data = []
    for tax in shared_genera:
        g = extract_genus(tax)
        ra16 = mean_ra_16s.get(tax, 0)
        ramgs = mean_ra_mgs.get(tax, 0)
        avg = (ra16 + ramgs) / 2
        ratio = ramgs / ra16 if ra16 > 0 else float('inf')
        shared_data.append((g, ra16, ramgs, ratio, avg))

    shared_data.sort(key=lambda x: x[4], reverse=True)
    for g, ra16, ramgs, ratio, avg in shared_data[:25]:
        ratio_str = f"{ratio:.2f}" if ratio != float('inf') else "∞"
        lines.append(f"| {g} | {ra16:.2f} | {ramgs:.2f} | {ratio_str} |")
    lines.append("")

    # Unique genera — only in 16S (top by abundance)
    lines.append("---")
    lines.append("")
    lines.append("## 5. Genera Unique to One Method")
    lines.append("")

    if only_16s:
        lines.append("### Unique to 16S (top 15 by mean RA)")
        lines.append("")
        lines.append("| Genus | Mean Rel. Abundance (%) |")
        lines.append("|-------|------------------------|")
        unique_16s_sorted = [(extract_genus(t), mean_ra_16s.get(t, 0)) for t in only_16s]
        unique_16s_sorted.sort(key=lambda x: x[1], reverse=True)
        for g, ra in unique_16s_sorted[:15]:
            lines.append(f"| {g} | {ra:.4f} |")
        lines.append("")

    if only_mgs:
        lines.append("### Unique to MGS (top 15 by mean RA)")
        lines.append("")
        lines.append("| Genus | Mean Rel. Abundance (%) |")
        lines.append("|-------|------------------------|")
        unique_mgs_sorted = [(extract_genus(t), mean_ra_mgs.get(t, 0)) for t in only_mgs]
        unique_mgs_sorted.sort(key=lambda x: x[1], reverse=True)
        for g, ra in unique_mgs_sorted[:15]:
            lines.append(f"| {g} | {ra:.4f} |")
        lines.append("")

    # Summary
    lines.append("---")
    lines.append("")
    lines.append("## 6. Summary & Key Observations")
    lines.append("")
    lines.append(f"- **16S** detected **{n_genera_16s}** genera across **{n_samples_16s}** samples (DADA2 + GG2 Naive Bayes classifier)")
    lines.append(f"- **MGS** detected **{n_genera_mgs}** genera across **{n_samples_mgs}** samples (Bowtie2 + WoLr2 + Woltka OGU)")
    lines.append(f"- **{len(shared_genera)}** genera were shared between both methods ({len(shared_genera)}/{len(genera_16s | genera_mgs)} = {100*len(shared_genera)/max(len(genera_16s | genera_mgs),1):.1f}% of total)")
    pct_only_16s = 100 * len(only_16s) / max(len(genera_16s), 1)
    pct_only_mgs = 100 * len(only_mgs) / max(len(genera_mgs), 1)
    lines.append(f"- **{len(only_16s)}** genera ({pct_only_16s:.1f}%) were unique to 16S")
    lines.append(f"- **{len(only_mgs)}** genera ({pct_only_mgs:.1f}%) were unique to MGS")
    lines.append("")
    lines.append("> **Note:** Both methods use the same Greengenes2 taxonomy, enabling direct genus-label comparison without additional harmonization.")
    lines.append("")

    # Write report
    with open(REPORT, "w") as f:
        f.write("\n".join(lines))

    print(f"Report written to: {REPORT}")
    print(f"  16S: {n_genera_16s} genera, {n_samples_16s} samples")
    print(f"  MGS: {n_genera_mgs} genera, {n_samples_mgs} samples")
    print(f"  Shared: {len(shared_genera)} genera")


if __name__ == "__main__":
    main()
