process LONGEST_ISOFORM {
    label 'process_single'
    publishDir "$params.outdir/Nucl/", mode:'copy', pattern: '*.nucl.fa'
    container 'quay.io/biocontainers/transdecoder:5.7.1--pl5321hdfd78af_2'

    input:
        path fasta_file
        val type

    output:
        path("${fasta_file}.nucl.fa") , emit: nucleotide

    script:
    """
	get_fasta_largest_isoform.TrinityMS.pl ${fasta_file} ${type}
	mv ${fasta_file}.largestIsoform ${fasta_file}.nucl.fa
    """
}
