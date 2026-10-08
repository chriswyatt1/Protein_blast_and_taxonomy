# Protein_blast_and_taxonomy: output

This describes the files the pipeline writes to the results folder (`results/` unless you set `--outdir`). A copy of this guide is saved in every results folder as `README.md`.

File names start with the name of your input file. When nucleotide input is translated, `.prot.fa` is added, so `transcripts.fa` becomes `transcripts.fa.prot.fa`.

| Folder | What it holds |
|--------|---------------|
| `report/` | **Start here.** A report of the whole run. |
| `Blast_results/` | The blast hits for each input file. |
| `Taxo_figure/` | Pie charts of the taxonomy of the top hits. |
| `Taxo_summary/` | The counts behind the pie charts, and per-sequence summaries. |
| `Prot/` | Proteins predicted from nucleotide input (`--nucleotide`, with diamond or blastp). |
| `Nucl/` | Transcripts searched by blastn (`--search_tool blastn`). |
| `database/` | The downloaded database (`--downloaddb_800GB` only). |
| `pipeline_info/` | The software versions used. |

## report/

- `Protein_blast_and_taxonomy_multiqc_report.html`: open this in a web browser. It shows:
  - how the pipeline was run and which database it used;
  - a summary for each input file: sequences searched, how many found a hit, how similar and how complete the top hits are, and how many taxa were hit;
  - charts of the identity and coverage of the top hits, and of their phylum and genus;
  - the contamination check (`--expected_taxon` only);
  - the taxonomy pie charts;
  - the software versions.
- `Protein_blast_and_taxonomy_multiqc_report_data/`: the tables behind the report as text files, e.g. `multiqc_search_summary_table.txt`.

## Blast_results/

- `<input>_results.tsv`: every hit kept for each sequence (up to `--numhits` per sequence, 100 by default), best first. Sequences with no hit are not listed. Tab-separated, with no header line. The columns are:

  | Column | Content |
  |--------|---------|
  | 1 | Query: your sequence's name |
  | 2 | Subject: the database sequence hit |
  | 3 | Subject title (description and species) |
  | 4 | Percent identity |
  | 5 | E-value |
  | 6 | Subject phylum (several are separated by `;`; `N/A` if none) |
  | 7 | Query coverage: % of your sequence covered by the alignment |
  | 8 | Subject NCBI taxonomy id (several are separated by `;`) |

- `<input>_results.tsv_top.tsv`: one line per sequence, its best hit (the lowest e-value). Same columns as above. It is not written with `--numhits 1`, where it would be the same as `<input>_results.tsv`.

The taxonomy files below are all made from each sequence's top hit.

## Taxo_figure/

- `Res_<input>_results.tsv_top.tsv_complete.pdf` and `.png`: eight pie charts of the taxonomy of the top hits, one for each rank: kingdom, phylum, class, order, family, genus, species, subspecies. The number above each chart is how many top hits have a taxon at that rank. Taxa with less than 1% of those hits are not labelled.

## Taxo_summary/

- `<input>_results.tsv_top.tsv_<rank>` (one file per rank, kingdom to subspecies): how many top hits belong to each taxon at that rank, most common first. Two columns: the taxon, and the count.
- `<input>_results.tsv_summary.tsv`: one line per sequence, listing the phyla of all its hits, each with the average percent identity and the number of hits. For example, `gene1	Arthropoda (64.20 of 87)	Chordata (41.50 of 13)` means 87 of gene1's hits are to arthropods. A gene whose hits are split across distant phyla may be worth a closer look.
- `<input>_outside_expected_taxon.tsv` (`--expected_taxon` only): the top hits outside the expected taxon, which may be contamination. It has a header line, the same columns as `<input>_results.tsv`, and a last column with the domain / phylum of the hit.

## Prot/

- `<input>.prot.fa`: the proteins searched. TransDecoder's first step predicts these from the longest transcript of each gene (see `--nucl_type`): every open reading frame of at least 100 amino acids. So a transcript can give several proteins, named `.p1`, `.p2` and so on.

## Nucl/

- `<input>.nucl.fa`: the longest transcript of each gene (see `--nucl_type`), as searched by blastn.

## database/

Only when the pipeline downloads the database (`--downloaddb_800GB`):

- `blastdb/`: the NCBI BLAST database (e.g. `nr.*`).
- `names.dmp`, `nodes.dmp`: the NCBI taxonomy.

These are hard links to the files in Nextflow's `work` folder, so they take no extra disk space. Move the `database` folder somewhere permanent, and use it on later runs with `--predownloaded database/blastdb --names database/names.dmp --nodes database/nodes.dmp`, so you only download it once.

## pipeline_info/

- `Protein_blast_and_taxonomy_software_mqc_versions.yml`: the versions of the main software used by each step, and of Nextflow and the pipeline.
