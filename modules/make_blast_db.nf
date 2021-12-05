process MAKE_DB {
    label 'blastdb'
    stageInMode 'copy'
    input:
        path nr_gz
        path prot_accession2taxid
        path nodes
        path names

    output:
        path 'nr.dmnd' , emit: blast_database

    script:
    """
	diamond makedb --in $nr_gz -d nr --taxonmap prot.accession2taxid.FULL --taxonnodes nodes.dmp --taxonnames names.dmp 
	rm $nr_gz
	#rm prot.accession2taxid.FULL
	#rm nodes.dmp
	#rm names.dmp
    """
} 

