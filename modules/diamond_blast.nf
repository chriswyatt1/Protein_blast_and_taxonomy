process DIAMOND_BLAST {
    label 'blast'
    container 'quay.io/biocontainers/diamond:2.2.8--he361c42_0'
    publishDir "$params.outdir/Blast_results/", mode:'copy'

    input:
        path proteins
        path database
        val db_name
        path nodes, stageAs: 'taxdump/nodes.dmp'
        path names, stageAs: 'taxdump/names.dmp'

    output:
        path("*_results.tsv") , emit: blast_hits
        path("database_info_mqc.html") , emit: db_info
        tuple val("${task.process}"), val('diamond'), eval("diamond version | sed 's/^diamond version //'"), emit: versions_diamond, topic: versions

    script:
    // --top (percentage range of the top score) overrides --max-target-seqs in diamond
    def hits = params.tophits ? "--top ${params.tophits}" : "--max-target-seqs ${params.numhits}"
    """
    # The database is a diamond .dmnd file, a folder holding ${db_name}.dmnd,
    # or a folder holding the NCBI BLAST database ${db_name} (taxonomy read from taxdump/)
    if [ -f ${database} ]; then
        db_path=${database}
        db_args="--db \$db_path"
    elif [ -f ${database}/${db_name}.dmnd ]; then
        db_path=${database}/${db_name}.dmnd
        db_args="--db \$db_path"
    else
        db_path=${database}/${db_name}
        db_args="--db \$db_path --taxdump taxdump"
    fi

    diamond blastp --${params.sensitivity} ${hits} --query ${proteins} \$db_args --out ${proteins}_results.tsv --threads ${task.cpus} --outfmt 6 qseqid sseqid stitle pident evalue sphylums staxids

    # For the report
    database_info.sh diamond ${database} \$db_path taxdump/nodes.dmp
    """
}
