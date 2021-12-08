process T_DECODER {
    label 'transdecoder'

    input:
	path fasta_file
               
    output:
        path("${fasta_file}.prot.fa") , emit: protein

    script:
    """
	TransDecoder.LongOrfs -t $fasta_file --output_dir Output
	cp Output/longest_orfs.pep ${fasta_file}.prot.fa
    """
} 
