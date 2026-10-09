# Changelog

The format follows the [nf-core](https://nf-co.re/) changelog style.

## [[v2.4.0](https://github.com/chriswyatt1/Protein_blast_and_taxonomy/releases/tag/v2.4.0)] - 2026-10-09

### Credits

- [Chris Wyatt](https://github.com/chriswyatt1)

### `Added`

- A **Methods description** section in the report, as nf-core pipelines have (`assets/methods_description_template.yml`), written for each run so it can be used in a publication:
  - methods text giving the pipeline and Nextflow versions, the input processing, the search tool with its version and settings, the database (title, release date and number of sequences), the NCBI Taxonomy files used, and the contamination check;
  - the command, and a table of every parameter value (including those set in config files and profiles);
  - references for the pipeline version and for the tools and data used in the run.

  A copy is saved as `pipeline_info/Protein_blast_and_taxonomy_methods_description.html`.
- `CITATIONS.md`, listing all the tools and data the pipeline can use, and a Citations section in the README.
- `manifest.doi` in `nextflow.config`: once a release has a Zenodo DOI, set it here and the methods description cites it.

### `Removed`

- The `--level` parameter, which has not been used since v1.

## [[v2.3.0](https://github.com/chriswyatt1/Protein_blast_and_taxonomy/releases/tag/v2.3.0)] - 2026-10-08

### Credits

- [Chris Wyatt](https://github.com/chriswyatt1)

### `Added`

- `docs/output.md`: a guide to every output file and the columns of the blast results. A copy is saved in the results folder as `README.md`.

### `Changed`

- **`--numhits` now defaults to 100 (was 1)**, so `<input>_results.tsv` keeps up to 100 hits per sequence, and the per-gene phylum summary (`Taxo_summary/<input>_results.tsv_summary.tsv`) shows how a gene's hits are spread across phyla. The results files are larger (about 20 times on the test data). Use `--numhits 1` for the previous behaviour.
- **The top hit of each sequence is now its best hit (lowest e-value)**, not the hit with the highest percent identity. This only matters with more than one hit per sequence. On the test data with 100 hits, the best hit is the same as the single hit from `--numhits 1` for all 341 sequences, so the taxonomy plots and report don't change. Picking by identity instead would have changed 142 of them, mostly to short partial matches (median coverage 45% vs 88%).

### `Fixed`

- `Blast_results/<input>_results.tsv_top.tsv` was the same as `<input>_results.tsv` with `--numhits 1`. It is no longer written in that case.
- `Blast_results/` no longer contains `database_info_mqc.html`, a file only meant for the report.

## [[v2.2.0](https://github.com/chriswyatt1/Protein_blast_and_taxonomy/releases/tag/v2.2.0)] - 2026-10-06

### Credits

- [Chris Wyatt](https://github.com/chriswyatt1)

### `Added`

- A report of the whole run, made with MultiQC: `results/report/Protein_blast_and_taxonomy_multiqc_report.html`. It contains:
  - run information: pipeline and Nextflow versions, the command, the search tool and its settings, and the database;
  - the database: its location, type, size and date (from `diamond dbinfo` or `blastdbcmd -info`), and the NCBI taxonomy files used;
  - a search summary for each input file: sequences searched, how many found a hit, how many top hits are ≥95% identical and how many of those cover ≥90% of the sequence, the median identity and coverage, and the number of phyla, genera and species hit;
  - interactive bar charts of the identity and the query coverage of the top hits (including sequences with no hit), and of the phylum and genus of the top hits;
  - the taxonomy pie chart figure;
  - the software versions.
- Software versions are collected with Nextflow topic channels, as nf-core modules do, and saved to `results/pipeline_info/Protein_blast_and_taxonomy_software_mqc_versions.yml`. Only the main programs are recorded: DIAMOND or BLAST+, TransDecoder and R, plus Nextflow and the pipeline version.
- The taxonomy pie chart figure is also saved as a PNG in `Taxo_figure/`.
- `--expected_taxon`: a contamination check. Give the taxon you sequenced (NCBI name or taxid); the report shows how many top hits are within it, groups those outside it by domain and phylum, and lists them in `Taxo_summary/*_outside_expected_taxon.tsv`. `-profile test` uses `Insecta`, as `Example.fasta` is honeybee.
- Query coverage (`qcovhsp`) of every hit, so a short high-identity match (e.g. one shared domain) can be told apart from a full-length one.

### `Changed`

- The blast results (`Blast_results/*_results.tsv`) have a new query coverage column before the subject taxonomy id, which stays the last column.
- The per-rank count tables in `Taxo_summary/` (`*_top.tsv_<rank>`) now have a `<rank>`/`count` header and no row numbers.

### `Fixed`

- The per-rank count tables were malformed when an input file's top hits had one taxon or none: R dropped the taxon names or the row numbers.
- `-profile test` failed on Nextflow 25.04 unless `--search_tool` was given (`Unknown config attribute params.search_tool`).

### Parameters

| Old parameter | New parameter      |
| ------------- | ------------------ |
|               | `--expected_taxon` |

> **NB:** Parameter has been **added** if just the new parameter information is present.

### `Dependencies`

| Dependency | Old version | New version |
| ---------- | ----------- | ----------- |
| `multiqc`  |             | 1.35        |

> **NB:** Dependency has been **added** if just the new version information is present.

## [[v2.1.0](https://github.com/chriswyatt1/Protein_blast_and_taxonomy/releases/tag/v2.1.0)] - 2026-10-06

### Credits

- [Chris Wyatt](https://github.com/chriswyatt1)

### `Added`

- `--search_tool blastp`: search proteins with NCBI BLAST+ blastp against an NCBI BLAST protein database such as nr ([#5](https://github.com/chriswyatt1/Protein_blast_and_taxonomy/issues/5)). Input is `--proteins`, or `--nucleotide` translated with TransDecoder, as for diamond. It is much slower than diamond: a large protein set against all of nr can take days.
- `--search_tool blastn`: search nucleotide transcripts with NCBI BLAST+ blastn (megablast) against an NCBI nucleotide database, `core_nt` by default ([#6](https://github.com/chriswyatt1/Protein_blast_and_taxonomy/issues/6)). The longest transcript per gene is searched directly, without TransDecoder, and published to `results/Nucl/`.
- NCBI BLAST output has the same columns as diamond's. `bin/add_phylum.pl` adds the phylum column from the NCBI taxonomy, so the taxonomy plots and summaries work unchanged.
- `--downloaddb_800GB` can download nucleotide databases, and prints the size of the database before downloading it.
- `-profile test` accepts `--search_tool blastp` or `--search_tool blastn`. The blastn test uses the small RefSeq Select RNA database (~0.1 GB, human and mouse only), so `Example.fasta` gets very few hits: it checks the steps run, not the biology.

### `Changed`

- `--blast_db` defaults to `core_nt` with `--search_tool blastn`, and stays `nr` otherwise. core_nt is NCBI's default nucleotide database (~260 GB download, ~305 GB on disk). Full `nt` (~1,032 GB download, ~1,210 GB on disk) is available with `--blast_db nt`; the README warns that it is bigger than the flag name says.
- The run stops before doing anything for option combinations that can't work: blastn without `--nucleotide`, `--tophits` with NCBI BLAST, NCBI BLAST against a `.dmnd` database, or an unknown `--search_tool`.
- The "no database" message gives the size of the database that would be downloaded.
- NCBI BLAST steps may run for up to 48 h (still limited by `--max_time`).

### Parameters

| Old parameter | New parameter   |
| ------------- | --------------- |
|               | `--search_tool` |

> **NB:** Parameter has been **added** if just the new parameter information is present.

### `Dependencies`

No new dependencies: NCBI BLAST runs in the BLAST+ 2.17.0 container already used to download databases.

## [[v2.0.0](https://github.com/chriswyatt1/Protein_blast_and_taxonomy/releases/tag/v2.0.0)] - 2026-10-06

### Credits

- [Chris Wyatt](https://github.com/chriswyatt1)

### `Added`

- `--downloaddb_800GB`: downloading a database is now opt-in. Without it or `--predownloaded`, the pipeline stops before running anything and explains both options.
- `-profile test`: an end-to-end run on the NCBI Swiss-Prot database (~225 MB) and `Example.fasta` that takes a few minutes.
- `--blast_db` to choose which NCBI BLAST protein database `--downloaddb_800GB` fetches (default `nr`).
- `--tophits` to keep every hit within a percentage of the best score (diamond `--top`), as an alternative to `--numhits`.
- `--predownloaded` accepts a DIAMOND `.dmnd` file, the folder containing `nr.dmnd`, or an NCBI BLAST database folder.
- The downloaded database is published to `results/database/` as hard links, ready to reuse with `--predownloaded`.
- Per-rank taxonomy count tables are published to `results/Taxo_summary/`.
- `CHANGELOG.md`, and a README section giving the size of each database option.

### `Changed`

- **Breaking:** requires Nextflow ≥ 25.04. The pipeline passes `nextflow lint` and runs on Nextflow 26 with the default strict syntax parser.
- **Breaking:** no database is downloaded unless you add `--downloaddb_800GB`. The recommended route is an existing DIAMOND database: `--predownloaded nr.dmnd --names names.dmp --nodes nodes.dmp`.
- **Breaking:** `--downloaddb_800GB` fetches NCBI's preformatted BLAST `nr` (~393 GB download, ~755 GB on disk) instead of the frozen `nr.gz`. DIAMOND searches it directly, so the `MAKE_DB` step and the `prot.accession2taxid` download are gone. Volumes are md5-checked and extracted one at a time.
- **Breaking:** `--max_cpus`, `--max_memory` and `--max_time` now cap every process through Nextflow's `resourceLimits`, which replaces the `check_max` function. The `myriad` and `cscluster` profiles raise the caps (6 CPUs, 40 GB) to keep their v1 resources.
- All containers are pinned and set only in the modules; profile configs no longer override them.

### `Fixed`

- Building a database from current NCBI data failed, because DIAMOND 2.0.13 rejects the `domain` rank NCBI added to the taxonomy in 2025.
- With a downloaded database, `PLOT_PIE` received `names.dmp` and `nodes.dmp` the wrong way round, so the taxonomy plots were empty.
- `DIAMOND_BLAST` passed `--top $params.tophits`, which was undefined, so diamond got `--top null`. `--numhits` works again.
- `*_top.tsv` and `*_summary.tsv` were never published, because their `publishDir` patterns matched undeclared outputs.
- Ranks containing spaces (e.g. `species group`) were read as `species`, inflating the species counts. On `Example.fasta` this gave 568 species for 341 proteins; it now gives 341.
- A missing input, or `--predownloaded` without `--names`/`--nodes`, now stops with a clear error before any work runs.
- The README example now uses `--nucl_type basic`. With the default `trinity`, `Example.fasta` collapsed from 560 transcripts to 5 "genes".

### `Removed`

- `MAKE_DB` (`modules/make_blast_db.nf`), the vendored TransDecoder 5.5.0 (`bin/TransDecoder.LongOrfs`, `bin/util/`), and the `docker/` recipes for the old `chriswyatt/*` images.

### Parameters

| Old parameter | New parameter        |
| ------------- | -------------------- |
|               | `--downloaddb_800GB` |
|               | `--blast_db`         |
|               | `--tophits`          |
|               | `--max_time`         |

> **NB:** Parameter has been **added** if just the new parameter information is present.

### `Dependencies`

| Dependency     | Old version | New version |
| -------------- | ----------- | ----------- |
| `diamond`      | 2.0.13      | 2.2.8       |
| `transdecoder` | 5.5.0       | 5.7.1       |
| `r-base`       | 4.1.0       | 4.6.1       |
| `blast`        | 2.11.0      | 2.17.0      |

> **NB:** Dependency has been **updated** if both old and new version information is present.
>
> **NB:** Dependency has been **added** if just the new version information is present.
>
> **NB:** Dependency has been **removed** if new version information isn't present.

Existing `nr.dmnd` databases keep working: one built with DIAMOND 2.0.15 gives identical hits and taxonomy with 2.2.8. TransDecoder 5.7.1 predicts the same 1,145 proteins as 5.5.0 on `Example.fasta`. Species and subspecies counts will differ from v1 results because of the rank fix above.
