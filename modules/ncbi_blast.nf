process NCBI_BLAST {
    label 'blast'
    container 'quay.io/biocontainers/blast:2.17.0--hb02a186_1'
    publishDir "$params.outdir/Blast_results/", mode:'copy', pattern: '*_results.tsv'

    input:
        path query
        path database
        val db_name
        val program
        path nodes, stageAs: 'taxdump/nodes.dmp'
        path names, stageAs: 'taxdump/names.dmp'

    output:
        path("*_results.tsv") , emit: blast_hits
        path("database_info_mqc.html") , emit: db_info
        tuple val("${task.process}"), val('blast'), eval("${program} -version | head -1 | sed 's/^.*: //'"), emit: versions_blast, topic: versions

    script:
    """
    # BLASTDB lets blast find the taxonomy files (taxdb.*) shipped with the database
    export BLASTDB=\$PWD/${database}

    ${program} -query ${query} -db ${database}/${db_name} -out blast_hits.tsv -num_threads ${task.cpus} -max_target_seqs ${params.numhits} -outfmt "6 qseqid sseqid stitle pident evalue qcovhsp staxids"

    # Add the phylum column, so the output matches diamond's (qseqid sseqid stitle pident evalue sphylums qcovhsp staxids)
    add_phylum.pl taxdump/nodes.dmp taxdump/names.dmp blast_hits.tsv > ${query}_results.tsv

    # For the report
    database_info.sh blast ${database} ${database}/${db_name} taxdump/nodes.dmp
    """
}
