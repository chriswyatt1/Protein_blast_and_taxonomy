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
params.search_tool = "diamond"
params.blast_db = false
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
include { LONGEST_ISOFORM } from './modules/longest_isoform.nf'
include { NCBI_BLAST } from './modules/ncbi_blast.nf'


workflow {
	def search_tool = params.search_tool
	// blastn searches nucleotides, so its default database is NCBI core_nt rather than nr
	def blast_db = params.blast_db ?: ( search_tool == "blastn" ? "core_nt" : "nr" )
	// Sizes as of October 2026, shown before anything is downloaded
	def db_sizes = [ nr: "~393 GB download, ~755 GB on disk", core_nt: "~260 GB download, ~305 GB on disk", nt: "~1,032 GB download, ~1,210 GB on disk" ]

	log.info """\
	 ===================================
	 Protein_blast_and_taxonomy v${workflow.manifest.version}
	 ===================================
	 proteins                             : ${params.proteins}
	 nucleotides                          : ${params.nucleotide}
	 search tool                          : ${search_tool}
	 database                             : ${params.predownloaded ?: (params.downloaddb_800GB ? "download NCBI ${blast_db}" : "none given")}
	 out directory                        : ${params.outdir}
	 """.stripIndent()

	// Check the options first, so nothing runs (or downloads) by accident
	if ( !( search_tool in ["diamond", "blastp", "blastn"] ) ){
		error "--search_tool must be diamond, blastp or blastn (not '${search_tool}')"
	}
	if ( search_tool == "blastn" && !params.nucleotide ){
		error "--search_tool blastn searches nucleotide sequences, so it needs --nucleotide input"
	}
	if ( search_tool == "blastn" && params.proteins ){
		error "--search_tool blastn needs --nucleotide input, not --proteins"
	}
	if ( params.tophits && search_tool != "diamond" ){
		error "--tophits only works with --search_tool diamond; use --numhits with NCBI blast"
	}
	if ( search_tool != "diamond" && params.predownloaded && !file(params.predownloaded).isDirectory() ){
		error "NCBI blast (--search_tool ${search_tool}) needs an NCBI BLAST database folder for --predownloaded, not a diamond .dmnd file"
	}
	if ( params.predownloaded && params.downloaddb_800GB ){
		error "Use either --predownloaded (an existing database) or --downloaddb_800GB (download a new one), not both"
	}
	if ( !params.predownloaded && !params.downloaddb_800GB ){
		error "No database given. Either:\n" +
			"  - point to an existing database: --predownloaded nr.dmnd --names names.dmp --nodes nodes.dmp\n" +
			"  - or download the NCBI ${blast_db} database (${db_sizes[blast_db] ?: "see the README for sizes"}) with --downloaddb_800GB\n" +
			"See the README for details."
	}
	if ( params.predownloaded && ( !params.names || !params.nodes ) ){
		error "--predownloaded also needs the taxonomy files: --names names.dmp --nodes nodes.dmp"
	}

	def input_queries
	if ( params.proteins ){
		input_queries = channel.fromPath(params.proteins, checkIfExists: true)
	}
	else if( params.nucleotide ){
		def input_target_nucleotide = channel.fromPath(params.nucleotide, checkIfExists: true)
		if ( search_tool == "blastn" ){
			// blastn searches the longest transcript per gene directly
			LONGEST_ISOFORM ( input_target_nucleotide , params.nucl_type )
			input_queries = LONGEST_ISOFORM.out.nucleotide
		}
		else{
			T_DECODER ( input_target_nucleotide , params.nucl_type )
			input_queries = T_DECODER.out.protein
		}
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
		log.info "Downloading the NCBI ${blast_db} database with taxonomy information\n"
		DOWNLOAD ( blast_db )
		input_database = DOWNLOAD.out.database
		input_nodes = DOWNLOAD.out.tax_nodes
		input_names = DOWNLOAD.out.tax_names
	}

	def blast_hits
	if ( search_tool == "diamond" ){
		DIAMOND_BLAST ( input_queries , input_database , blast_db , input_nodes , input_names )
		blast_hits = DIAMOND_BLAST.out.blast_hits
	}
	else{
		NCBI_BLAST ( input_queries , input_database , blast_db , search_tool , input_nodes , input_names )
		blast_hits = NCBI_BLAST.out.blast_hits
	}
	PLOT_PIE ( input_nodes , input_names , blast_hits )

	workflow.onComplete = {
		println ( workflow.success ? "\nDone! Results are in --> $params.outdir\n" : "Hmmm .. something went wrong" )
	}
}
