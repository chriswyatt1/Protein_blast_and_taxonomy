process MULTIQC {
    label 'process_single'
    container 'quay.io/biocontainers/multiqc:1.35--pyhdfd78af_2'
    publishDir "$params.outdir/report/", mode:'copy'

    input:
        path report_files, stageAs: '?/*'
        path multiqc_config

    output:
        // Named after the report title in the config: Protein_blast_and_taxonomy_multiqc_report.html
        path("*multiqc_report.html") , emit: report
        path("*multiqc_report_data") , emit: data
        // No versions topic here: MultiQC reads the collated versions, and states its own version in the report

    script:
    """
    multiqc --force --config ${multiqc_config} .
    """
}
