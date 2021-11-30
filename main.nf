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

include { DOWNLOAD } from './modules/download.nf'
include { DIAMOND_BLAST } from './modules/diamond_blast.nf'
include { MAKE_DB } from './modules/make_blast_db.nf'

input_target_proteins = channel
	.fromPath(params.proteins)
	.ifEmpty { error "Cannot find the list of protein files: ${params.proteins}" }
  

workflow {
	DOWNLOAD ()
	MAKE_DB ( DOWNLOAD.out.database )
	DIAMOND_BLAST ( input_target_proteins , MAKE_DB.out.blast_database )
}

workflow.onComplete {
	println ( workflow.success ? "\nDone! Open your report in your browser --> $params.outdir/report.html (if you added -with-report flag)\n" : "Hmmm .. something went wrong" )
}
