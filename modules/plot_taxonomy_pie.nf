process PLOT_PIE {
    label 'perl_pie'
    publishDir "$params.outdir/Blast_results/"
    //stageInMode 'copy'
    
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
	${workflow.projectDir}/bin/ncbi_txids_taxonomy.all.pl $nodes $names $blast_result
    """
}
