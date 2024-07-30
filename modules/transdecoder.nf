process T_DECODER {
    label 'process_low'
    publishDir "$params.outdir/Prot/", mode:'copy', pattern: '*.prot.fa'
    container = 'chriswyatt/transdecoder'

    input:
        path fasta_file
        val type

    output:
        path("${fasta_file}.prot.fa") , emit: protein

    script:
    """
	get_fasta_largest_isoform.TrinityMS.pl $fasta_file $type
	TransDecoder.LongOrfs -t ${fasta_file}.largestIsoform --output_dir Output
	cp Output/longest_orfs.pep ${fasta_file}.prot.fa
    """
} 
