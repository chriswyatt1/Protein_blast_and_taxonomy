process PLOT_PIE {
    label 'perl_pie'
    container 'rocker/r-ver:4.6.1'
    publishDir "$params.outdir/Blast_results/", mode:'copy', pattern: '*_top.tsv'
    publishDir "$params.outdir/Taxo_figure/", mode:'copy', pattern: '*.pdf'
    publishDir "$params.outdir/Taxo_summary/", mode:'copy', pattern: '*_summary.tsv'
    publishDir "$params.outdir/Taxo_summary/", mode:'copy', pattern: '*_top.tsv_{kingdom,phylum,class,order,family,genus,species,subspecies}'

    input:
	path nodes
	path names
        path blast_result

    output:
        path("*.pdf") , emit: pies
	path("*_top.tsv") , emit: top_hits
	path("*_summary.tsv") , emit: summary
	path("*_top.tsv_{kingdom,phylum,class,order,family,genus,species,subspecies}") , emit: rank_counts

    script:
    """
	tophitsonly.pl ${blast_result}
	mv tophitsonly.tsv ${blast_result}_top.tsv
	ncbi_txids_taxonomy.all.pl ${nodes} ${names} ${blast_result}_top.tsv

	blast2taxgenesummary.pl ${blast_result}
    """
}
