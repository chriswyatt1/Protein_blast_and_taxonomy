process PLOT_PIE {
    label 'perl_pie'
    publishDir "$params.outdir/Blast_results/", mode:'copy', pattern: '*top.tsv'
    publishDir "$params.outdir/Taxo_figure/", mode:'copy', pattern: '*.pdf'
    publishDir "$params.outdir/Taxo_summary/", mode:'copy', pattern: '*_summary.tsv'
    
    input:
	path nodes
	path names
        path blast_result
               
    output:
        path("*.pdf") , emit: pies
	path("*genus")
	path("*phylum")
	
    script:
    """
	${workflow.projectDir}/bin/tophitsonly.pl $blast_result
	mv tophitsonly.tsv ${blast_result}_top.tsv
	${workflow.projectDir}/bin/ncbi_txids_taxonomy.all.pl $nodes $names ${blast_result}_top.tsv

	blast2taxgenesummary.pl $blast_result
    """
}
