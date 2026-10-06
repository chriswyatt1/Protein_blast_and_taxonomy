#!/usr/bin/env bash
# Writes the Database section of the report: where the database and taxonomy files are,
# and what the search tool reports about the database.
set -euo pipefail

tool=${1:?Usage: database_info.sh <diamond|blast> <database file or folder> <database as given to the search tool> <nodes.dmp>}
location=$2
db=$3
nodes=$4

{
    echo "<!--"
    echo "id: 'database_info'"
    echo "section_name: 'Database'"
    echo "description: 'The database searched, and the NCBI taxonomy used to name the hits.'"
    echo "-->"
    echo '<dl class="dl-horizontal">'
    echo "<dt>Database</dt><dd>$(readlink -f "$location")</dd>"
    if [ "$tool" = "diamond" ]; then
        # Lines such as "              Sequences  487728"
        diamond dbinfo -d "$db" 2>/dev/null | sed -nE 's#^ *([A-Za-z][A-Za-z ]*[a-z])  +(.+)$#<dt>\1</dt><dd>\2</dd>#p'
    else
        blastdbcmd -db "$db" -info | awk '
            /^Database: /      { sub(/^Database: /, ""); print "<dt>Title</dt><dd>" $0 "</dd>" }
            /sequences;/       { gsub(/^[ \t]+/, ""); print "<dt>Size</dt><dd>" $0 "</dd>" }
            /^Date: /          { split($0, a, "\t"); sub(/^Date: /, "", a[1]); print "<dt>Date</dt><dd>" a[1] "</dd>" }
            /^BLASTDB Version/ { print "<dt>BLAST database version</dt><dd>" $3 "</dd>" }'
    fi
    echo "<dt>Taxonomy</dt><dd>$(readlink -f "$nodes") (modified $(date -r "$nodes" +%Y-%m-%d))</dd>"
    echo '</dl>'
} > database_info_mqc.html
