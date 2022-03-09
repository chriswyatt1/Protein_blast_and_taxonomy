process NCBI_BLAST {
    label 'ncbiblast'
    publishDir "$params.outdir/Blast_results/"
    
    input:
        path proteins
        path ('*')
               
    output:
        path("*_results.tsv") , emit: blast_hits

    script:
    """
    blastp -query ${proteins} -max_target_seqs 30 -db nr -out ${proteins}\_results.tsv -num_threads $task.cpus -outfmt ${params.blast_outformat}
    rm nr.*
    rm $proteins
    """
}
