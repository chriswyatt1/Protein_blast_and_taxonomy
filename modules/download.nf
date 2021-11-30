process DOWNLOAD {
    label 'download'
               
    output:
        path("nr.gz") , emit: database

    script:
    """
    wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz
    """
} 
