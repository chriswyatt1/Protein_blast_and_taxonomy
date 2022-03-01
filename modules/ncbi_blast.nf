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
    blastp -query ${proteins} -db nr -out ${proteins}\_results.tsv -num_threads $task.cpus -outfmt 5
    rm nr.*
    rm $proteins
    """
}
