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
    diamond blastp --sensitive --max-target-seqs 1 --query $proteins --db nr --out ${proteins}\_results.tsv --threads $task.cpus --outfmt 6 qseqid sseqid evalue sphylums staxids
    rm nr.dmnd
    rm $proteins
    """
}
