process DIAMOND_BLAST {
    label 'blast'
    publishDir "$params.outdir/Blast_results/"
    //stageInMode 'copy'
    
    input:
        path '*.fa'
        path 'database'
               
    output:
        path("results.tsv") , emit: blast_hits

    script:
    """
    diamond blastp -in --db $database  --out results.tsv --threads $task.cpus --outfmt 6 qseqid  
    """
}
