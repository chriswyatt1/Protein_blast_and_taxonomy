#!/usr/bin/env bash
# Download an NCBI preformatted BLAST database (e.g. nr, swissprot, core_nt).
# Volumes are fetched one at a time, md5 checked, extracted and the archive
# removed, so peak disk use stays close to the size of the extracted database.
set -euo pipefail

db=${1:?Usage: download_blastdb.sh <database name, e.g. nr> [output directory]}
outdir=${2:-blastdb}
base=https://ftp.ncbi.nlm.nih.gov/blast/db

mkdir -p "$outdir"
cd "$outdir"

# Protein databases have a -prot- metadata file, nucleotide ones a -nucl- one
if ! wget -q --tries=5 -O "${db}-metadata.json" "${base}/${db}-prot-metadata.json"; then
    if ! wget -q --tries=5 -O "${db}-metadata.json" "${base}/${db}-nucl-metadata.json"; then
        echo "Could not find the NCBI BLAST database '${db}' at ${base}" >&2
        exit 1
    fi
fi
volumes=$(grep -oE "${db}(\.[0-9]+)?\.tar\.gz" "${db}-metadata.json" | sort -u || true)
if [ -z "$volumes" ]; then
    echo "No volumes found for NCBI BLAST database '${db}'" >&2
    exit 1
fi
download_gb=$(grep -oE '"bytes-total-compressed": *[0-9]+' "${db}-metadata.json" | grep -oE '[0-9]+$' | awk '{printf "%.1f", $1/1e9}' || true)
disk_gb=$(grep -oE '"bytes-total": *[0-9]+' "${db}-metadata.json" | grep -oE '[0-9]+$' | awk '{printf "%.1f", $1/1e9}' || true)
echo "Downloading ${db}: $(echo "$volumes" | wc -l | tr -d ' ') volume(s), ~${download_gb} GB download, ~${disk_gb} GB on disk"

for vol in $volumes; do
    echo "Downloading ${vol}"
    wget -q --tries=5 --continue "${base}/${vol}"
    wget -q --tries=5 -O "${vol}.md5" "${base}/${vol}.md5"
    md5sum -c "${vol}.md5"
    tar -xzf "${vol}"
    rm "${vol}" "${vol}.md5"
done
