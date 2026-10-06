#!/usr/bin/env bash
# Download an NCBI preformatted BLAST protein database (e.g. nr, swissprot).
# Volumes are fetched one at a time, md5 checked, extracted and the archive
# removed, so peak disk use stays close to the size of the extracted database.
set -euo pipefail

db=${1:?Usage: download_blastdb.sh <database name, e.g. nr> [output directory]}
outdir=${2:-blastdb}
base=https://ftp.ncbi.nlm.nih.gov/blast/db

mkdir -p "$outdir"
cd "$outdir"

wget -q --tries=5 -O "${db}-prot-metadata.json" "${base}/${db}-prot-metadata.json"
volumes=$(grep -oE "${db}(\.[0-9]+)?\.tar\.gz" "${db}-prot-metadata.json" | sort -u)
if [ -z "$volumes" ]; then
    echo "No volumes found for NCBI BLAST protein database '${db}'" >&2
    exit 1
fi

for vol in $volumes; do
    echo "Downloading ${vol}"
    wget -q --tries=5 --continue "${base}/${vol}"
    wget -q --tries=5 -O "${vol}.md5" "${base}/${vol}.md5"
    md5sum -c "${vol}.md5"
    tar -xzf "${vol}"
    rm "${vol}" "${vol}.md5"
done
