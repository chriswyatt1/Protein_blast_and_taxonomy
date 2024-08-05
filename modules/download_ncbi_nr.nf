process DOWNLOAD_NCBI_NR {
    label 'download_nr'
    time 24.h
    container 'ncbi/blast:latest'
    
    output:
        path("nr*") , emit: database

    script:
    """
        update_blastdb.pl --decompress nr [*]     
    """
} 
