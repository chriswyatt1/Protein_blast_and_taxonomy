process DIAMOND_XML {
    label 'blast'
    publishDir "$params.outdir/Blast_results/", mode:'copy'
    //stageInMode 'copy'
    
    input:
        path proteins
        path ('nr.dmnd')

    output:
        path("*_results.xml") , emit: blast_hits

    script:
    """
        diamond blastp --$params.sensitivity --max-target-seqs $params.numhits --query $proteins --db nr --out ${proteins}\_results.xml --threads $task.cpus --outfmt 5 

        #rm nr.dmnd
        #rm $proteins
    """
}
