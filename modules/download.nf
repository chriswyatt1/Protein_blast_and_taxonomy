process DOWNLOAD {
    label 'download_nr'
    time 24.h
    container 'quay.io/biocontainers/blast:2.17.0--hb02a186_1'
    publishDir "$params.outdir/database/", mode:'link', failOnError: false

    output:
        path("blastdb") , emit: database
        path("nodes.dmp") , emit: tax_nodes
        path("names.dmp") , emit: tax_names

    script:
    """
    download_blastdb.sh ${params.blast_db} blastdb
    wget -q --tries=5 https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdmp.zip
    unzip -o taxdmp.zip nodes.dmp names.dmp
    rm taxdmp.zip
    """
}
