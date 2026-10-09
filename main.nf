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
params.numhits = 100
params.tophits = false
params.sensitivity= "fast"
params.expected_taxon = false
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

// Numbers such as 487728 shown as 487,728
def formatCount(number) {
	return number ? String.format('%,d', number.toString() as long) : 'an unknown number of'
}

// In-text citation and reference for each tool and database the methods description can mention
def methodsReferences() {
	return [
		diamond: [
			cite: '<a href="https://doi.org/10.1038/s41592-021-01101-x">Buchfink <em>et al.</em>, 2021</a>',
			ref: 'Buchfink, B., Reuter, K., & Drost, H.-G. (2021). Sensitive protein alignments at tree-of-life scale using DIAMOND. Nature Methods, 18(4), 366–368. doi: <a href="https://doi.org/10.1038/s41592-021-01101-x">10.1038/s41592-021-01101-x</a>'
		],
		blast: [
			cite: '<a href="https://doi.org/10.1186/1471-2105-10-421">Camacho <em>et al.</em>, 2009</a>',
			ref: 'Camacho, C., Coulouris, G., Avagyan, V., Ma, N., Papadopoulos, J., Bealer, K., & Madden, T. L. (2009). BLAST+: architecture and applications. BMC Bioinformatics, 10, 421. doi: <a href="https://doi.org/10.1186/1471-2105-10-421">10.1186/1471-2105-10-421</a>'
		],
		transdecoder: [
			cite: '<a href="https://github.com/TransDecoder/TransDecoder">Haas, TransDecoder</a>',
			ref: 'Haas, B. J. TransDecoder. <a href="https://github.com/TransDecoder/TransDecoder">https://github.com/TransDecoder/TransDecoder</a>'
		],
		r: [
			cite: 'R Core Team, 2026',
			ref: 'R Core Team (2026). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. <a href="https://www.R-project.org/">https://www.R-project.org/</a>'
		],
		multiqc: [
			cite: '<a href="https://doi.org/10.1093/bioinformatics/btw354">Ewels <em>et al.</em>, 2016</a>',
			ref: 'Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics, 32(19), 3047–3048. doi: <a href="https://doi.org/10.1093/bioinformatics/btw354">10.1093/bioinformatics/btw354</a>'
		],
		taxonomy: [
			cite: '<a href="https://doi.org/10.1093/database/baaa062">Schoch <em>et al.</em>, 2020</a>',
			ref: 'Schoch, C. L., Ciufo, S., Domrachev, M., Hotton, C. L., Kannan, S., Khovanskaya, R., Leipe, D., Mcveigh, R., O’Neill, K., Robbertse, B., Sharma, S., Soussov, V., Sullivan, J. P., Sun, L., Turner, S., & Karsch-Mizrachi, I. (2020). NCBI Taxonomy: a comprehensive update on curation, resources and tools. Database, 2020, baaa062. doi: <a href="https://doi.org/10.1093/database/baaa062">10.1093/database/baaa062</a>'
		],
		ncbi: [
			cite: '<a href="https://doi.org/10.1093/nar/gkaf1060">Sayers <em>et al.</em>, 2026</a>',
			ref: 'Sayers, E. W., Bolton, E. E., Fine, A. M., Kelly, C., Kim, S., Landrum, M., Lathrop, S., Malheiro, A., Murphy, T. D., Phan, L., Pujar, S., Trawick, B. W., Schneider, V. A., & Pruitt, K. D. (2026). Database resources of the National Center for Biotechnology Information in 2026. Nucleic Acids Research, 54(D1), D20–D27. doi: <a href="https://doi.org/10.1093/nar/gkaf1060">10.1093/nar/gkaf1060</a>'
		],
		uniprot: [
			cite: '<a href="https://doi.org/10.1093/nar/gkae1010">The UniProt Consortium, 2025</a>',
			ref: 'The UniProt Consortium (2025). UniProt: the Universal Protein Knowledgebase in 2025. Nucleic Acids Research, 53(D1), D609–D617. doi: <a href="https://doi.org/10.1093/nar/gkae1010">10.1093/nar/gkae1010</a>'
		],
		docker: [
			cite: 'Merkel, 2014',
			ref: 'Merkel, D. (2014). Docker: lightweight Linux containers for consistent development and deployment. Linux Journal, 2014(239), 2.'
		],
		singularity: [
			cite: '<a href="https://doi.org/10.1371/journal.pone.0177459">Kurtzer <em>et al.</em>, 2017</a>',
			ref: 'Kurtzer, G. M., Sochat, V., & Bauer, M. W. (2017). Singularity: Scientific containers for mobility of compute. PLOS ONE, 12(5), e0177459. doi: <a href="https://doi.org/10.1371/journal.pone.0177459">10.1371/journal.pone.0177459</a>'
		]
	]
}

// In-text citation, remembering which references to list
def cite(references, used, key) {
	if ( !used.contains(key) ) {
		used.add(key)
	}
	return references[key].cite
}

// The report's methods description, as nf-core pipelines provide, from assets/methods_description_template.yml.
// It is written for this run (tools and versions used, settings, database and taxonomy), so it can go in a publication.
def methodsDescriptionText(template, versions_file, database_file, search_tool, blast_db) {
	def references = methodsReferences()
	def used = []
	// "  tool: version" lines of the collated versions file
	def versions = versions_file.readLines()
		.findAll { line -> line.startsWith('  ') }
		.collectEntries { line -> [ (line.trim().tokenize(':')[0]): line.trim().substring(line.trim().indexOf(':') + 1).trim() ] }
	// "key<tab>value" lines written by database_info.sh
	def db = database_file.readLines()
		.collectEntries { line -> [ (line.tokenize('\t')[0]): line.contains('\t') ? line.substring(line.indexOf('\t') + 1) : '' ] }

	def release_url = "https://github.com/chriswyatt1/Protein_blast_and_taxonomy/releases/tag/v${workflow.manifest.version}"
	def doi = workflow.manifest.doi ? workflow.manifest.doi.toString().replace('https://doi.org/', '').trim() : ''
	def doi_link = doi ? "doi: <a href=\"https://doi.org/${doi}\">${doi}</a>" : ''
	def engine = workflow.containerEngine
	def engine_text = engine == 'docker' ? ", run with Docker (${cite(references, used, 'docker')})"
		: engine == 'singularity' ? ", run with Singularity (${cite(references, used, 'singularity')})"
		: engine == 'apptainer' ? ", run with Apptainer, formerly Singularity (${cite(references, used, 'singularity')})"
		: ""

	def sentences = []
	sentences.add("Sequences were analysed with Protein_blast_and_taxonomy v${workflow.manifest.version} (<a href=\"${release_url}\">${doi ? doi_link : release_url}</a>) using Nextflow v${workflow.nextflow.version} (<a href=\"https://doi.org/10.1038/nbt.3820\">Di Tommaso <em>et al.</em>, 2017</a>), with software containers from the Bioconda (<a href=\"https://doi.org/10.1038/s41592-018-0046-7\">Grüning <em>et al.</em>, 2018</a>) and BioContainers (<a href=\"https://doi.org/10.1093/bioinformatics/btx192\">da Veiga Leprevost <em>et al.</em>, 2017</a>) projects${engine_text}.")

	// Input
	def nucleotide_input = !params.proteins && params.nucleotide
	def gene_text = params.nucl_type == 'trinity' ? "the longest transcript of each gene was kept (genes taken from the Trinity sequence names, without the isoform suffix)"
		: params.nucl_type == 'ensembl' ? "the longest transcript of each gene was kept (genes taken from the Ensembl gene identifiers in the sequence names)"
		: "all transcripts were used"
	if ( nucleotide_input && search_tool != 'blastn' ) {
		sentences.add("For each nucleotide input, ${gene_text}, and open reading frames encoding at least 100 amino acids were predicted with TransDecoder.LongOrfs from TransDecoder v${versions.transdecoder} (${cite(references, used, 'transdecoder')}).")
	}
	else if ( nucleotide_input ) {
		sentences.add("For each nucleotide input, ${gene_text}.")
	}

	// Search
	def db_text
	def database_note = ''
	if ( db.Title ) {
		def db_reference = ( blast_db == 'swissprot' || db.Title.contains('SwissProt') ) ? cite(references, used, 'uniprot') : cite(references, used, 'ncbi')
		db_text = "the NCBI ${escapeHtml(blast_db)} BLAST database (${escapeHtml(db.Title)}${db.Date ? ", version of ${db.Date}" : ''}, ${formatCount(db.Sequences)} sequences; ${db_reference})"
	}
	else {
		db_text = "a DIAMOND database (${escapeHtml(file(db.Location).name)}, ${formatCount(db.Sequences)} sequences)"
		database_note = "<li>A DIAMOND database does not record where its sequences came from: add the source and version of <code>${escapeHtml(file(db.Location).name)}</code> (e.g. NCBI nr, downloaded on a given date) to the text, with its reference.</li>"
	}
	def query_text = search_tool == 'blastn' ? "The transcripts" : nucleotide_input ? "The predicted proteins" : "Protein sequences"
	def hits_text = ( params.tophits && search_tool == 'diamond' ) ? "keeping all hits within ${params.tophits}% of the best hit's score (--top ${params.tophits})"
		: "keeping up to ${params.numhits} hits per sequence (${search_tool == 'diamond' ? '--max-target-seqs' : '-max_target_seqs'} ${params.numhits})"
	if ( search_tool == 'diamond' ) {
		sentences.add("${query_text} were searched against ${db_text} with DIAMOND v${versions.diamond} blastp (${cite(references, used, 'diamond')}) in --${params.sensitivity} mode, ${hits_text}.")
	}
	else {
		def program = search_tool == 'blastn' ? 'blastn (megablast)' : 'blastp'
		sentences.add("${query_text} were searched against ${db_text} with NCBI BLAST+ v${versions.blast} ${program} (${cite(references, used, 'blast')}), ${hits_text}.")
	}

	// Taxonomy and report
	sentences.add("Hits were assigned to taxa with the NCBI Taxonomy (${cite(references, used, 'taxonomy')})${db['Taxonomy date'] ? ", using taxonomy files dated ${db['Taxonomy date']}" : ''}. The best hit of each sequence (lowest e-value) was used to summarise the taxonomy of the hits from kingdom to subspecies, with pie charts drawn in R v${versions['r-base']} (${cite(references, used, 'r')}).")
	if ( params.expected_taxon ) {
		sentences.add("To flag possible contamination, sequences whose best hit was outside ${escapeHtml(params.expected_taxon)} were counted and grouped by domain and phylum.")
	}
	sentences.add("The results were summarised in a report made with MultiQC (${cite(references, used, 'multiqc')}).")

	def parameter_rows = params.keySet().sort().collect { name -> "<tr><td><code>--${name}</code></td><td>${escapeHtml(params.get(name))}</td></tr>" }.join('')

	def meta = [
		pipeline_version: workflow.manifest.version,
		pipeline_link: doi ? doi_link : "<a href=\"${release_url}\">${release_url}</a>",
		methods_text: sentences.join(' '),
		command_line: escapeHtml(workflow.commandLine),
		parameters_table: "<table class=\"table table-condensed\"><thead><tr><th>Parameter</th><th>Value</th></tr></thead><tbody>${parameter_rows}</tbody></table>",
		tool_bibliography: used.collect { key -> "<li>${references[key].ref}</li>" }.join(' '),
		nodoi_text: doi ? '' : "<li>This version of the pipeline has no DOI: cite it by its release, <a href=\"${release_url}\">${release_url}</a>.</li>",
		database_note: database_note
	]
	return new groovy.text.SimpleTemplateEngine().createTemplate(template.text).make(meta).toString()
}

// The methods description as a web page, to copy into a publication
def methodsHtmlPage(methods_yaml) {
	def html = methods_yaml.substring(methods_yaml.indexOf('data: |') + 'data: |'.length())
		.readLines()
		.collect { line -> line.startsWith('  ') ? line.substring(2) : line }
		.join('\n')
	return "<!DOCTYPE html>\n<html><head><meta charset=\"utf-8\"><title>Protein_blast_and_taxonomy methods description</title></head><body>\n${html}\n</body></html>\n".toString()
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
	def database_details
	if ( search_tool == "diamond" ){
		DIAMOND_BLAST ( input_queries , input_database , blast_db , input_nodes , input_names )
		blast_hits = DIAMOND_BLAST.out.blast_hits
		database_info = DIAMOND_BLAST.out.db_info
		database_details = DIAMOND_BLAST.out.db_details
	}
	else{
		NCBI_BLAST ( input_queries , input_database , blast_db , search_tool , input_nodes , input_names )
		blast_hits = NCBI_BLAST.out.blast_hits
		database_info = NCBI_BLAST.out.db_info
		database_details = NCBI_BLAST.out.db_details
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

	// Methods description for a publication: in the report, and as a page in pipeline_info
	def methods_description = versions_yml
		.combine( database_details.first() )
		.map { versions, database -> methodsDescriptionText(file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true), versions, database, search_tool, blast_db) }
	methods_description
		.map { methods_yaml -> methodsHtmlPage(methods_yaml) }
		.collectFile( name: 'Protein_blast_and_taxonomy_methods_description.html', storeDir: "${params.outdir}/pipeline_info" )

	def report_files = PLOT_PIE.out.mqc.flatten()
		.mix( database_info.first() )
		.mix( channel.of(run_info_html).collectFile(name: 'run_info_mqc.html') )
		.mix( versions_yml )
		.mix( methods_description.collectFile(name: 'methods_description_mqc.yaml') )
		.collect()
	MULTIQC ( report_files , file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true) )

	// Save the guide to the output files in the results folder
	channel.fromPath("${projectDir}/docs/output.md", checkIfExists: true)
		.collectFile(name: 'README.md', storeDir: params.outdir)

	workflow.onComplete = {
		println ( workflow.success ? "\nDone! Results are in --> $params.outdir (report: $params.outdir/report/Protein_blast_and_taxonomy_multiqc_report.html)\n" : "Hmmm .. something went wrong" )
	}
}
