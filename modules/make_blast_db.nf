process MAKE_DB {
    label 'blastdb'
    //stageInMode 'copy'
    input:
        path 'nr.gz'
    output:
        path("nr") , emit: blast_database

    script:
    """
    diamond makedb --in $nr.gz -d nr
    """
} 

