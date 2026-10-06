process PLOT_PIE {
    label 'perl_pie'
    container 'rocker/r-ver:4.6.1'
    publishDir "$params.outdir/Blast_results/", mode:'copy', pattern: '*_top.tsv'
    publishDir "$params.outdir/Taxo_figure/", mode:'copy', pattern: '*.{pdf,png}'
    publishDir "$params.outdir/Taxo_summary/", mode:'copy', pattern: '*_{summary,outside_expected_taxon}.tsv'
    publishDir "$params.outdir/Taxo_summary/", mode:'copy', pattern: '*_top.tsv_{kingdom,phylum,class,order,family,genus,species,subspecies}'

    input:
	path nodes
	path names
        tuple path(query), path(blast_result)

    output:
        path("*.pdf") , emit: pies
	path("*.png") , emit: pies_png
	path("*_top.tsv") , emit: top_hits
	path("*_summary.tsv") , emit: summary
	path("*_top.tsv_{kingdom,phylum,class,order,family,genus,species,subspecies}") , emit: rank_counts
	path("*_outside_expected_taxon.tsv") , optional: true, emit: outside_expected_taxon
	path("*_mqc.{tsv,html}") , emit: mqc
	tuple val("${task.process}"), val('r-base'), eval("R --version | head -1 | sed 's/^R version //; s/ .*//'"), emit: versions_r, topic: versions

    script:
    // Name each input in the report as given, without the .prot.fa / .nucl.fa added by the pipeline
    def sample = query.name.replaceAll(/\.(prot|nucl)\.fa$/, '')
    // With --expected_taxon, check which top hits fall outside it (possible contamination)
    def expected_check = params.expected_taxon ? "expected_taxon.pl ${nodes} ${names} ${blast_result}_top.tsv '${params.expected_taxon}' ${sample}" : ""
    def expected_counts = params.expected_taxon ? "${sample}_expected_taxon_counts.txt" : ""
    """
	tophitsonly.pl ${blast_result}
	mv tophitsonly.tsv ${blast_result}_top.tsv
	ncbi_txids_taxonomy.all.pl ${nodes} ${names} ${blast_result}_top.tsv

	blast2taxgenesummary.pl ${blast_result}

	# For the report
	${expected_check}
	report_stats.pl ${sample} ${query} ${blast_result}_top.tsv Res_${blast_result}_top.tsv_complete.png ${expected_counts}
    """
}
