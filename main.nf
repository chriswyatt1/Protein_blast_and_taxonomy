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
params.expected_taxon = false
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
include { MULTIQC } from './modules/multiqc.nf'

// Make text safe to show in the HTML report
def escapeHtml(text) {
	return text.toString().replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
}

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
	def database_info
	if ( search_tool == "diamond" ){
		DIAMOND_BLAST ( input_queries , input_database , blast_db , input_nodes , input_names )
		blast_hits = DIAMOND_BLAST.out.blast_hits
		database_info = DIAMOND_BLAST.out.db_info
	}
	else{
		NCBI_BLAST ( input_queries , input_database , blast_db , search_tool , input_nodes , input_names )
		blast_hits = NCBI_BLAST.out.blast_hits
		database_info = NCBI_BLAST.out.db_info
	}

	// Pair each query file with its hits, so the report can count the sequences searched
	def queries_by_name = input_queries.map { query -> [ query.name, query ] }
	def hits_by_name = blast_hits.map { hits -> [ hits.name - '_results.tsv', hits ] }
	PLOT_PIE ( input_nodes , input_names , queries_by_name.join(hits_by_name).map { _name, query, hits -> [ query, hits ] } )

	//================================================================================
	// Report: run information, database, results summary and software versions
	//================================================================================

	// Collate the software versions each process sends to the versions topic (as nf-core does)
	def versions_yml = channel.topic("versions")
		.distinct()
		.map { process, tool, version -> [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ] }
		.groupTuple(by: 0)
		.map { process, tool_versions -> "${process}:\n${tool_versions.unique().sort().join('\n')}".toString() }
		// toString(): Nextflow 25.04 cannot pass its version object through collectFile
		.mix( channel.of("Workflow:\n  Nextflow: ${workflow.nextflow.version}\n  Protein_blast_and_taxonomy: v${workflow.manifest.version}".toString()) )
		.collectFile( storeDir: "${params.outdir}/pipeline_info", name: 'Protein_blast_and_taxonomy_software_mqc_versions.yml', sort: true, newLine: true )

	def search_settings = search_tool != "diamond" ? "${params.numhits} hit(s) per sequence"
		: params.tophits ? "--${params.sensitivity}, hits within ${params.tophits}% of the top score"
		: "--${params.sensitivity}, ${params.numhits} hit(s) per sequence"
	def run_info_html = [
		"<!--",
		"id: 'run_info'",
		"section_name: 'Run information'",
		"-->",
		"<dl class=\"dl-horizontal\">",
		"<dt>Pipeline</dt><dd>Protein_blast_and_taxonomy v${workflow.manifest.version}</dd>",
		"<dt>Nextflow</dt><dd>${workflow.nextflow.version}</dd>",
		"<dt>Run name</dt><dd>${workflow.runName}</dd>",
		"<dt>Started</dt><dd>${workflow.start}</dd>",
		"<dt>Command</dt><dd><code>${escapeHtml(workflow.commandLine)}</code></dd>",
		"<dt>Input</dt><dd>${escapeHtml(params.proteins ?: params.nucleotide)}</dd>",
		"<dt>Search tool</dt><dd>${search_tool} (${search_settings})</dd>",
		"<dt>Expected taxon</dt><dd>${escapeHtml(params.expected_taxon ?: "not set (--expected_taxon)")}</dd>",
		"<dt>Database</dt><dd>${escapeHtml(params.predownloaded ?: "NCBI ${blast_db}, downloaded by this run (saved in ${params.outdir}/database/)")}</dd>",
		"</dl>"
	].join("\n")

	def report_files = PLOT_PIE.out.mqc.flatten()
		.mix( database_info.first() )
		.mix( channel.of(run_info_html).collectFile(name: 'run_info_mqc.html') )
		.mix( versions_yml )
		.collect()
	MULTIQC ( report_files , file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true) )

	workflow.onComplete = {
		println ( workflow.success ? "\nDone! Results are in --> $params.outdir (report: $params.outdir/report/Protein_blast_and_taxonomy_multiqc_report.html)\n" : "Hmmm .. something went wrong" )
	}
}
