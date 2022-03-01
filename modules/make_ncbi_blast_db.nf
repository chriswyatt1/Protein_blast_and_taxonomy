process MAKE_NCBI_DB {
    label 'ncbi_blastdb'
    //stageInMode 'copy'
    output:
        path 'n*' , emit: blast_database

    script:
    """
	update_blastdb.pl --decompress nr
    """
} 
