process DOWNLOAD {
    label 'download'

    output:
        path("nr.gz") , emit: database
        path("prot.accession2taxid.FULL") , emit: accession2taxid
        path("nodes.dmp") , emit: tax_nodes
        path("names.dmp") , emit: tax_names

    script:
    """
    wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz
    wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.gz
    wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdmp.zip
    unzip taxdmp.zip
    gunzip prot.accession2taxid.FULL.gz     
    """
} 
