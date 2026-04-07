#!/usr/bin/env bash
set -e
##############################################################################
#  Pipeline 3 — One-time environment setup
#
#  Installs SortMeRNA into a dedicated conda environment.
#  SortMeRNA ships with bundled SILVA rRNA databases for 16S/18S/23S/28S.
#
#  Usage:  bash setup_pipeline3.sh
##############################################################################

echo "=== Creating sortmerna conda environment ==="
conda create -n sortmerna -c conda-forge -c bioconda sortmerna=4.3.7 -y

echo ""
echo "=== Verifying installation ==="
conda run -n sortmerna sortmerna --version

echo ""
echo "=== Locating bundled rRNA databases ==="
SMR_DB=$(conda run -n sortmerna python -c "import site; import os; dirs=site.getsitepackages(); [print(os.path.join(d,'sortmerna','rRNA_databases')) for d in dirs if os.path.isdir(os.path.join(d,'sortmerna','rRNA_databases'))]" 2>/dev/null || true)

if [[ -z "$SMR_DB" ]]; then
    # Try common conda location
    SMR_PREFIX=$(conda run -n sortmerna python -c "import sys; print(sys.prefix)")
    SMR_DB="${SMR_PREFIX}/share/sortmerna/rRNA_databases"
fi

if [[ -d "$SMR_DB" ]]; then
    echo "SortMeRNA rRNA databases found at: $SMR_DB"
    ls "$SMR_DB"/*.fasta 2>/dev/null | head -5
else
    echo "WARNING: Could not locate bundled rRNA databases."
    echo "You may need to download SILVA databases manually."
    echo "Check: conda run -n sortmerna sortmerna -h"
fi

echo ""
echo "=== Verifying Kraken2 ==="
module load kraken/2.17.1 2>/dev/null && kraken2 --version | head -1 || echo "WARNING: kraken module not available"

echo ""
echo "=== Done ==="
echo "Environments ready:"
echo "  - sortmerna  (16S extraction from WGS reads)"
echo "  - kraken/2.17.1 module  (taxonomic classification)"
echo "  - Bracken: /DCEG/Projects/Microbiome/Metagenomics/Kraken/Bracken/bracken"
