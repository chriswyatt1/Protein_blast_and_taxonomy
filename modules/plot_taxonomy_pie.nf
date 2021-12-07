process PLOT_PIE {
    label 'perl_pie'
    publishDir "$params.outdir/Blast_results/"
    //stageInMode 'copy'
    
    input:
	path nodes
	path names
        path blast_result
	val level
               
    output:
        path("*.pdf") , emit: pies

    script:
    """
	${workflow.projectDir}/bin/ncbi_txids_taxonomy.pl $nodes $names $blast_result $level
    """
}
