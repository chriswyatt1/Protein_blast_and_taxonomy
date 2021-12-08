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

params.proteins= false
params.nucleotide = false
params.predownloaded= false
params.outdir = "results"
params.names = false
params.nodes = false
params.level = "family"

log.info """\
 ===================================
 proteins                             : ${params.proteins}
 nucleotides                          : ${params.nucleotide}
 out directory                        : ${params.outdir}
 """

//================================================================================
// Include modules
//================================================================================

include { DOWNLOAD } from './modules/download.nf'
include { MAKE_DB } from './modules/make_blast_db.nf'
include { DIAMOND_BLAST } from './modules/diamond_blast.nf'
include { PLOT_PIE } from './modules/plot_taxonomy_pie.nf'
include { T_DECODER } from './modules/transdecoder.nf'


workflow {
	if ( params.proteins ){
        	input_target_proteins = channel
        	.fromPath(params.proteins)
        	.ifEmpty { error "Cannot find the list of protein files: ${params.proteins}" }
	}
	else if( params.nucleotide ){
		input_target_nucleotide = channel
                .fromPath(params.nucleotide)
                .ifEmpty { error "Cannot find the list of protein files: ${params.nucleotide}" }
		T_DECODER ( input_target_nucleotide )
		T_DECODER.out.protein.set{ input_target_proteins }
	}
	else{
		println "You have not set the input protein or nucleotide option\n"
	}


	if ( !params.predownloaded ){
		// If not predownloaded then wget all from NCBI.
		println "Downloading a new nr database with taxonomy information\n"
		DOWNLOAD ()
		MAKE_DB ( DOWNLOAD.out.database , DOWNLOAD.out.accession2taxid , DOWNLOAD.out.tax_nodes , DOWNLOAD.out.tax_names )
		DIAMOND_BLAST ( input_target_proteins , MAKE_DB.out.blast_database )
		PLOT_PIE ( DOWNLOAD.out.tax_names , DOWNLOAD.out.tax_nodes , DIAMOND_BLAST.out.blast_hits , params.level  )
	}
	else{
		input_database = channel
			.fromPath(params.predownloaded)
			.ifEmpty { error "Cannot find the blast database : ${params.predownloaded}" }
		input_names = channel
                        .fromPath(params.names)
                        .ifEmpty { error "Cannot find the blast database : ${params.names}" }
		input_nodes = channel
                        .fromPath(params.nodes)
                        .ifEmpty { error "Cannot find the blast database : ${params.nodes}" }
		DIAMOND_BLAST ( input_target_proteins , input_database )
		PLOT_PIE ( input_nodes , input_names , DIAMOND_BLAST.out.blast_hits , params.level  )
	}
}

workflow.onComplete {
	println ( workflow.success ? "\nDone! Open your report in your browser --> $params.outdir/report.html (if you added -with-report flag)\n" : "Hmmm .. something went wrong" )
}
