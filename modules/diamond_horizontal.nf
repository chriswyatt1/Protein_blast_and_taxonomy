process DIAMOND_HORIZONTAL {
    label 'blast'
    publishDir "$params.outdir/Blast_results/", mode:'copy'
    //stageInMode 'copy'
    
    input:
        path proteins
        path ('nr.dmnd')

    output:
        path("*_horizresults.tsv") , emit: blast_hits

    script:
    """
        diamond blastp --fast --top 10 --query $proteins --db nr --out ${proteins}\_horizresults.tsv --threads $task.cpus --outfmt 6 qseqid sseqid stitle pident evalue sphylums staxids sscinames
        #rm nr.dmnd
        #rm $proteins
    """
}
