process DIAMOND_BLAST {
    label 'blast'
    publishDir "$params.outdir/Blast_results/"
    //stageInMode 'copy'
    
    input:
        path 'proteins.fa'
        path 'db'
               
    output:
        path("results.tsv") , emit: blast_hits

    script:
    """
    diamond blastp --in $proteins.fa --db $db --out results.tsv --threads $task.cpus --outfmt 6 qseqid skingdoms
    """
}
