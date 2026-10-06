/*
 * Copyright (c) 2021
 */


 /*
 * Authors:
 * - Chris Wyatt <chris.wyatt@seqera.io>
 */

params.proteins= false
params.nucleotide = false
params.nucl_type = "trinity"
params.blast_db = "nr"
params.predownloaded= false
params.downloaddb_800GB = false
params.names = false
params.nodes = false
params.numhits = 1
params.tophits = false
params.sensitivity= "fast"
params.level = "family"
params.outdir = "results"

//================================================================================
// Include modules
//================================================================================

include { DOWNLOAD } from './modules/download.nf'
include { DIAMOND_BLAST } from './modules/diamond_blast.nf'
include { PLOT_PIE } from './modules/plot_taxonomy_pie.nf'
include { T_DECODER } from './modules/transdecoder.nf'


workflow {
	log.info """\
	 ===================================
	 Protein_blast_and_taxonomy v${workflow.manifest.version}
	 ===================================
	 proteins                             : ${params.proteins}
	 nucleotides                          : ${params.nucleotide}
	 database                             : ${params.predownloaded ?: (params.downloaddb_800GB ? "download NCBI ${params.blast_db}" : "none given")}
	 out directory                        : ${params.outdir}
	 """.stripIndent()

	// Check the database options first, so nothing runs (or downloads) by accident
	if ( params.predownloaded && params.downloaddb_800GB ){
		error "Use either --predownloaded (an existing database) or --downloaddb_800GB (download a new one), not both"
	}
	if ( !params.predownloaded && !params.downloaddb_800GB ){
		error "No database given. Either:\n" +
			"  - point to an existing database: --predownloaded nr.dmnd --names names.dmp --nodes nodes.dmp\n" +
			"  - or download the NCBI nr database (~393 GB download, ~755 GB on disk) with --downloaddb_800GB\n" +
			"See the README for details."
	}
	if ( params.predownloaded && ( !params.names || !params.nodes ) ){
		error "--predownloaded also needs the taxonomy files: --names names.dmp --nodes nodes.dmp"
	}

	def input_target_proteins
	if ( params.proteins ){
		input_target_proteins = channel.fromPath(params.proteins, checkIfExists: true)
	}
	else if( params.nucleotide ){
		def input_target_nucleotide = channel.fromPath(params.nucleotide, checkIfExists: true)
		T_DECODER ( input_target_nucleotide , params.nucl_type )
		input_target_proteins = T_DECODER.out.protein
	}
	else{
		error "You have not set the input protein (--proteins) or nucleotide (--nucleotide) option"
	}

	def input_database
	def input_nodes
	def input_names
	if ( params.predownloaded ){
		input_database = channel.value( file(params.predownloaded, checkIfExists: true) )
		input_nodes = channel.value( file(params.nodes, checkIfExists: true) )
		input_names = channel.value( file(params.names, checkIfExists: true) )
	}
	else{
		// Only with --downloaddb_800GB: download the BLAST database and taxonomy from NCBI.
		log.info "Downloading the NCBI ${params.blast_db} database with taxonomy information\n"
		DOWNLOAD ()
		input_database = DOWNLOAD.out.database
		input_nodes = DOWNLOAD.out.tax_nodes
		input_names = DOWNLOAD.out.tax_names
	}

	DIAMOND_BLAST ( input_target_proteins , input_database , input_nodes , input_names )
	PLOT_PIE ( input_nodes , input_names , DIAMOND_BLAST.out.blast_hits )

	workflow.onComplete = {
		println ( workflow.success ? "\nDone! Results are in --> $params.outdir\n" : "Hmmm .. something went wrong" )
	}
}
