# Protein_blast_and_taxonomy: Citations

The report of each run (`report/Protein_blast_and_taxonomy_multiqc_report.html`, section *Methods description*) has methods text and references for that run, including the versions used. A copy is saved in `pipeline_info/Protein_blast_and_taxonomy_methods_description.html`.

## [Protein_blast_and_taxonomy](https://github.com/chriswyatt1/Protein_blast_and_taxonomy)

> Wyatt, C. Protein_blast_and_taxonomy, version <version>. https://github.com/chriswyatt1/Protein_blast_and_taxonomy/releases/tag/v<version>

Cite the version you used; the report's methods description fills it in.

## [Nextflow](https://doi.org/10.1038/nbt.3820)

> Di Tommaso, P., Chatzou, M., Floden, E. W., Barja, P. P., Palumbo, E., & Notredame, C. (2017). Nextflow enables reproducible computational workflows. Nature Biotechnology, 35(4), 316–319. doi: 10.1038/nbt.3820

## Pipeline tools

- [DIAMOND](https://doi.org/10.1038/s41592-021-01101-x) (`--search_tool diamond`, the default)

  > Buchfink, B., Reuter, K., & Drost, H.-G. (2021). Sensitive protein alignments at tree-of-life scale using DIAMOND. Nature Methods, 18(4), 366–368. doi: 10.1038/s41592-021-01101-x

- [BLAST+](https://doi.org/10.1186/1471-2105-10-421) (`--search_tool blastp` or `blastn`)

  > Camacho, C., Coulouris, G., Avagyan, V., Ma, N., Papadopoulos, J., Bealer, K., & Madden, T. L. (2009). BLAST+: architecture and applications. BMC Bioinformatics, 10, 421. doi: 10.1186/1471-2105-10-421

- [TransDecoder](https://github.com/TransDecoder/TransDecoder) (`--nucleotide` input, with diamond or blastp)

  > Haas, B. J. TransDecoder. https://github.com/TransDecoder/TransDecoder

- [R](https://www.R-project.org/)

  > R Core Team (2026). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. https://www.R-project.org/

- [MultiQC](https://doi.org/10.1093/bioinformatics/btw354)

  > Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics, 32(19), 3047–3048. doi: 10.1093/bioinformatics/btw354

## Data

- [NCBI Taxonomy](https://doi.org/10.1093/database/baaa062)

  > Schoch, C. L., Ciufo, S., Domrachev, M., Hotton, C. L., Kannan, S., Khovanskaya, R., Leipe, D., Mcveigh, R., O’Neill, K., Robbertse, B., Sharma, S., Soussov, V., Sullivan, J. P., Sun, L., Turner, S., & Karsch-Mizrachi, I. (2020). NCBI Taxonomy: a comprehensive update on curation, resources and tools. Database, 2020, baaa062. doi: 10.1093/database/baaa062

- [NCBI BLAST databases](https://doi.org/10.1093/nar/gkaf1060) (e.g. nr, core_nt, nt)

  > Sayers, E. W., Bolton, E. E., Fine, A. M., Kelly, C., Kim, S., Landrum, M., Lathrop, S., Malheiro, A., Murphy, T. D., Phan, L., Pujar, S., Trawick, B. W., Schneider, V. A., & Pruitt, K. D. (2026). Database resources of the National Center for Biotechnology Information in 2026. Nucleic Acids Research, 54(D1), D20–D27. doi: 10.1093/nar/gkaf1060

- [UniProt](https://doi.org/10.1093/nar/gkae1010) (the swissprot database)

  > The UniProt Consortium (2025). UniProt: the Universal Protein Knowledgebase in 2025. Nucleic Acids Research, 53(D1), D609–D617. doi: 10.1093/nar/gkae1010

## Software packaging/containerisation tools

- [Bioconda](https://doi.org/10.1038/s41592-018-0046-7)

  > Grüning, B., Dale, R., Sjödin, A., Chapman, B. A., Rowe, J., Tomkins-Tinch, C. H., Valieris, R., Köster, J., & Bioconda Team. (2018). Bioconda: sustainable and comprehensive software distribution for the life sciences. Nature Methods, 15(7), 475–476. doi: 10.1038/s41592-018-0046-7

- [BioContainers](https://doi.org/10.1093/bioinformatics/btx192)

  > da Veiga Leprevost, F., Grüning, B. A., Alves Aflitos, S., Röst, H. L., Uszkoreit, J., Barsnes, H., Vaudel, M., Moreno, P., Gatto, L., Weber, J., Bai, M., Jimenez, R. C., Sachsenberg, T., Pfeuffer, J., Vera Alvarez, R., Griss, J., Nesvizhskii, A. I., & Perez-Riverol, Y. (2017). BioContainers: an open-source and community-driven framework for software standardization. Bioinformatics, 33(16), 2580–2582. doi: 10.1093/bioinformatics/btx192

- [Rocker](https://doi.org/10.32614/RJ-2017-065) (the R container)

  > Boettiger, C., & Eddelbuettel, D. (2017). An Introduction to Rocker: Docker Containers for R. The R Journal, 9(2), 527–536. doi: 10.32614/RJ-2017-065

- [Docker](https://www.linuxjournal.com/node/1335702)

  > Merkel, D. (2014). Docker: lightweight Linux containers for consistent development and deployment. Linux Journal, 2014(239), 2.

- [Singularity / Apptainer](https://doi.org/10.1371/journal.pone.0177459)

  > Kurtzer, G. M., Sochat, V., & Bauer, M. W. (2017). Singularity: Scientific containers for mobility of compute. PLOS ONE, 12(5), e0177459. doi: 10.1371/journal.pone.0177459
