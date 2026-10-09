#!/usr/bin/env bash
# Describes the database and taxonomy used, for the report: database_info.tsv (key, value; used for the
# methods description) and database_info_mqc.html (the report's Database section).
set -euo pipefail

tool=${1:?Usage: database_info.sh <diamond|blast> <database file or folder> <database as given to the search tool> <nodes.dmp>}
location=$2
db=$3
nodes=$4

: > database_info.tsv
add() { printf '%s\t%s\n' "$1" "$2" >> database_info.tsv; }

add "Location" "$(readlink -f "$location")"

# NCBI BLAST databases describe themselves in a JSON file (<db>.pjs or .njs, or the metadata file
# saved by --downloaddb_800GB)
json=""
for f in "$db.pjs" "$db.njs" "$db-metadata.json" "$db-prot-metadata.json" "$db-nucl-metadata.json"; do
    if [ -f "$f" ]; then json=$f; break; fi
done
jget() { sed -nE "s/^ *\"$1\": *\"?([^\",]*)\"?,?\$/\\1/p" "$json" | head -1; }

if [ -n "$json" ]; then
    add "Type" "NCBI BLAST database"
    add "Title" "$(jget description)"
    add "Date" "$(jget last-updated | cut -c1-10)"
    add "Sequences" "$(jget number-of-sequences)"
    add "Letters" "$(jget number-of-letters)"
elif [ "$tool" = "diamond" ]; then
    # Lines such as "              Sequences  487728"
    diamond dbinfo -d "$db" 2>/dev/null | sed -nE 's/^ *([A-Za-z][A-Za-z ]*[a-z])  +(.+)$/\1\t\2/p' >> database_info.tsv
else
    add "Type" "NCBI BLAST database"
    blastdbcmd -db "$db" -info | awk -F'\t' '
        /^Database: / { sub(/^Database: /, ""); print "Title\t" $0 }
        /sequences;/  { gsub(/[ ,\t]/, ""); split($0, a, /sequences;|totalresidues|totalbases/); print "Sequences\t" a[1]; print "Letters\t" a[2] }
        /^Date: /     { sub(/^Date: /, "", $1); sub(/  .*/, "", $1); print "Date\t" $1 }' >> database_info.tsv
fi

add "Taxonomy" "$(readlink -f "$nodes")"
add "Taxonomy date" "$(date -r "$nodes" +%Y-%m-%d)"

{
    echo "<!--"
    echo "id: 'database_info'"
    echo "section_name: 'Database'"
    echo "description: 'The database searched, and the NCBI taxonomy used to name the hits.'"
    echo "-->"
    echo '<dl class="dl-horizontal">'
    awk -F'\t' '{ print "<dt>" $1 "</dt><dd>" $2 "</dd>" }' database_info.tsv
    echo '</dl>'
} > database_info_mqc.html
