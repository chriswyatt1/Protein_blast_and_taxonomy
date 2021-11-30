/*
 * Copyright (c) 2021
 */
 

 /*
 * Authors:
 * - Chris Wyatt <chris.wyatt@seqera.io>
 */

/* 
 * enable modules 
 */
nextflow.enable.dsl = 2

/*
 * Default pipeline parameters (on test data). They can be overriden on the command line eg.
 * given `params.genome` specify on the run command line `--genome /path/to/Duck_genome.fasta`.
 */

params.proteins="Human_olfactory.fasta.gz"
params.outdir = "results"

log.info """\
 ===================================
 proteins                             : ${params.proteins}
 out directory                        : ${params.outdir}
 """

//================================================================================
// Include modules
//================================================================================

include { DIAMOND_BLAST } from './modules/diamond_blast.nf'


input_target_proteins = channel
	.fromPath(params.proteins)
	.ifEmpty { error "Cannot find the list of protein files: ${params.proteins}" }
  

workflow {
	MAKE_DB ()
	DIAMOND_BLAST ( input_target_proteins )
}

workflow.onComplete {
	println ( workflow.success ? "\nDone! Open your report in your browser --> $params.outdir/report.html (if you added -with-report flag)\n" : "Hmmm .. something went wrong" )
}
