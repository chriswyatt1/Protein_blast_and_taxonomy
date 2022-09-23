process T_DECODER {
    label 'transdecoder'

    input:
	path fasta_file
               
    output:
        path("${fasta_file}.prot.fa") , emit: protein

    script:
    """
	get_fasta_largest_isoform.TrinityMS.pl $fasta_file $params.nucl_type
	TransDecoder.LongOrfs -t ${fasta_file}.largestIsoform --output_dir Output
	cp Output/longest_orfs.pep ${fasta_file}.prot.fa
    """
} 
