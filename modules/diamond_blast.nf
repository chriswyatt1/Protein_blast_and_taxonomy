process DIAMOND_BLAST {
    label 'blast'
    container 'quay.io/biocontainers/diamond:2.2.8--he361c42_0'
    publishDir "$params.outdir/Blast_results/", mode:'copy'

    input:
        path proteins
        path database
        path nodes, stageAs: 'taxdump/nodes.dmp'
        path names, stageAs: 'taxdump/names.dmp'

    output:
        path("*_results.tsv") , emit: blast_hits

    script:
    // --top (percentage range of the top score) overrides --max-target-seqs in diamond
    def hits = params.tophits ? "--top ${params.tophits}" : "--max-target-seqs ${params.numhits}"
    """
    # The database is a diamond .dmnd file, a folder holding ${params.blast_db}.dmnd,
    # or a folder holding the NCBI BLAST database ${params.blast_db} (taxonomy read from taxdump/)
    if [ -f ${database} ]; then
        db_args="--db ${database}"
    elif [ -f ${database}/${params.blast_db}.dmnd ]; then
        db_args="--db ${database}/${params.blast_db}.dmnd"
    else
        db_args="--db ${database}/${params.blast_db} --taxdump taxdump"
    fi

    diamond blastp --${params.sensitivity} ${hits} --query ${proteins} \$db_args --out ${proteins}_results.tsv --threads ${task.cpus} --outfmt 6 qseqid sseqid stitle pident evalue sphylums staxids
    """
}
