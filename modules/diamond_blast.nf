process DIAMOND_BLAST {
    label 'blast'
    container = 'chriswyatt/diamond'
    publishDir "$params.outdir/Blast_results/", mode:'copy'
    
    input:
        path proteins
        path ('nr.dmnd')

    output:
        path("*_results.tsv") , emit: blast_hits

    script:
    """
	diamond blastp --$params.sensitivity --top $params.tophits --query $proteins --db nr --out ${proteins}\_results.tsv --threads $task.cpus --outfmt 6 qseqid sseqid stitle pident evalue sphylums staxids
    	#rm nr.dmnd
    	#rm $proteins
    """
}
