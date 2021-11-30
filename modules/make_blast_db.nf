process MAKE_DB {
    label 'blastdb'
    //stageInMode 'copy'
               
    output:
        path("nr") , emit: blast_database

    script:
    """
    wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz
    diamond makedb --in nr.gz -d nr
    """
} 

