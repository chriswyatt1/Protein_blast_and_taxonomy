/*
 * Copyright (c) 2021
 */

/*
 * Authors:
 * - Chris Wyatt <chris.wyatt@seqera.io>
 */

params.proteins= false
params.nucleotide = false
params.predownloaded= false
params.outdir = "results"
params.names = false
params.nodes = false
params.numhits = null
params.tophits = null
params.level = "family"
params.sensitivity = "fast"
params.horizontal = false
params.xml = false

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
include { PLOT_PIE } from './modules/plot_taxonomy_pie.nf'
include { T_DECODER } from './modules/transdecoder.nf'
include { DIAMOND_BLAST } from './modules/diamond_blast.nf'
include { DIAMOND_HORIZONTAL } from './modules/diamond_horizontal.nf'
include { DIAMOND_XML } from './modules/diamond_xml.nf'

workflow {
	input_database = Channel.empty()
	input_names    = Channel.empty()
	input_nodes    = Channel.empty()

	if ( !params.predownloaded ){
		// If not predownloaded then wget all from NCBI.
		println "Downloading a new nr database with taxonomy information\n"
		DOWNLOAD ()
		MAKE_DB ( DOWNLOAD.out.database , DOWNLOAD.out.accession2taxid , DOWNLOAD.out.tax_nodes , DOWNLOAD.out.tax_names )
		MAKE_DB.out.blast_database.first().set{ input_database }
		DOWNLOAD.out.tax_names.first().set{ input_names }
		DOWNLOAD.out.tax_nodes.first().set{ input_nodes }
	}
	else{
		input_database = channel
			.fromPath(params.predownloaded)
			.ifEmpty { error "Cannot find the blast database : ${params.predownloaded}" }
			.first()
		input_names = channel
            .fromPath(params.names)
            .ifEmpty { error "Cannot find the blast database : ${params.names}" }
			.first()
		input_nodes = channel
            .fromPath(params.nodes)
            .ifEmpty { error "Cannot find the blast database : ${params.nodes}" }
            .first()
	}

	input_target_proteins = Channel.empty()

	if ( params.proteins ){
		input_target_proteins = channel
		.fromPath(params.proteins)
		.splitCsv()
		.ifEmpty { error "Cannot find the list of protein files: ${params.proteins}" }
	}
	else if( params.nucleotide ){
		input_target_nucleotide = channel
                .fromPath(params.nucleotide)
		.splitCsv()
                .ifEmpty { error "Cannot find the list of protein files: ${params.nucleotide}" }
		T_DECODER ( input_target_nucleotide )
		T_DECODER.out.protein.set{ input_target_proteins }
	}
	else{
		println "You have not set the input protein or nucleotide option\n"
	}


	DIAMOND_BLAST ( input_target_proteins , input_database )
	
	PLOT_PIE ( input_nodes , input_names , DIAMOND_BLAST.out.blast_hits )

	//if ( params.horizontal ){
	//	DIAMOND_HORIZONTAL ( input_target_proteins , input_database )
	//}

	if ( params.xml ){
		DIAMOND_XML ( input_target_proteins , input_database )
	}
}

workflow.onComplete {
	println ( workflow.success ? "\nDone! Open your report in your browser --> $params.outdir/report.html (if you added -with-report flag)\n" : "Hmmm .. something went wrong" )
}
