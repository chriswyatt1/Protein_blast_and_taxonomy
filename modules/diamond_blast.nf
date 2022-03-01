process DIAMOND_BLAST {
    label 'blast'
    publishDir "$params.outdir/Blast_results/"
    stageInMode 'copy'
    
    input:
        path proteins
        path ('nr.dmnd')
               
    output:
        path("*_results.tsv") , emit: blast_hits

    script:
    """
    diamond blastp --$params.sensitivity --max-target-seqs ${params.numblasthits} --query ${proteins} --db nr --out ${proteins}\_results.tsv --threads $task.cpus --outfmt ${params.format} qseqid sseqid evalue sphylums staxids
    rm nr.dmnd
    rm $proteins
    """
}
