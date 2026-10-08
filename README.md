# Protein_blast_and_taxonomy

Nextflow pipeline to run diamond blast (or NCBI blastp / blastn) and retrieve family level names for each protein or transcript.

Version 2 brings the pipeline up to date with Nextflow 26 and current NCBI data. See [CHANGELOG.md](CHANGELOG.md) for what changed from v1.

# Pre-requisites

- You must be on a unix machine (mac, linux etc.) or cluster.
- Nextflow 25.04 or newer (https://www.nextflow.io/docs/latest/getstarted.html). Tested on Nextflow 26.04.
- LOCAL: requires Docker (https://docs.docker.com/get-docker/). On Apple Silicon Macs the containers run under Docker's x86 emulation, which works but is slow for large searches.
- SUN GRID ENGINE CLUSTER: requires Singularity or Apptainer. Normally already on the HPC Sun Grid Engine clusters.
- A protein database to search against, ideally an existing DIAMOND database (`.dmnd`). See [The database](#the-database) for the options and their sizes.
- Git (optional) (https://github.com/git-guides/install-git). So you can git clone the repo.

# Setting up

First, you need to clone the repository from github `git clone https://github.com/chriswyatt1/Protein_blast_and_taxonomy.git`, if you have git installed, OR download the zip folder from `https://github.com/chriswyatt1/Protein_blast_and_taxonomy`, then unzip it and `cd` into this directory.

Second, if you have proteins (one per gene) already, you can run with the `--proteins` flag. If you have nucleotide transcripts, use the `--nucleotide` flag, which keeps the longest transcript per gene and finds the open reading frames with TransDecoder. Tell the pipeline how your fasta headers are formatted with `--nucl_type`:

- `trinity` (default): Trinity headers such as `TRINITY_DN1000_c0_g1_i1`. The isoform suffix (`_i1`) is removed to group isoforms into genes.
- `ensembl`: Ensembl cDNA headers, grouped by the gene ID after the first `:`.
- `basic`: any other headers. Every sequence is kept as its own gene (this is what `Example.fasta` needs).

Third, you need to choose your environment profile. Use `-profile docker` for a local run with Docker, `-profile myriad` for UCL's Myriad cluster, `-profile cscluster` for the UCL CS cluster, or `-profile apptainer` for Apptainer.

Fourth, choose the search tool with `--search_tool` (see [Search tool](#search-tool)). The default, `diamond`, is the fastest.

The final consideration is the database, described next.

# The database

The pipeline never downloads a database unless you ask it to. You must either point it to an existing database with `--predownloaded`, or explicitly ask for the NCBI nr download with `--downloaddb_800GB`. If you give neither, it stops straight away and tells you the options.

| Database | Size on disk | How to use it |
|----------|--------------|---------------|
| An existing DIAMOND database, e.g. a shared `nr.dmnd` (**recommended**) | ~350 GB for nr built from NCBI's last nr FASTA (Feb 2024). No download. | `--predownloaded /path/to/nr.dmnd` |
| NCBI nr, downloaded by the pipeline in BLAST format | **~393 GB download, ~755 GB on disk: you need about 800 GB free** | `--downloaddb_800GB` |
| NCBI core_nt (nucleotides, for `--search_tool blastn`), downloaded in BLAST format | ~260 GB download, ~305 GB on disk | `--search_tool blastn --downloaddb_800GB` |
| NCBI nt (all nucleotides) | **~1,032 GB download, ~1,210 GB on disk: more than the flag name says** | `--search_tool blastn --downloaddb_800GB --blast_db nt` |
| NCBI Swiss-Prot, for testing | ~225 MB download, ~0.7 GB on disk | `-profile test` |
| NCBI taxonomy (`names.dmp`, `nodes.dmp`), always needed | ~80 MB download, ~540 MB on disk | `--names` and `--nodes` |

Sizes are as of October 2026. NCBI nr roughly doubles every two years, so expect these to grow. The download step prints the size of the database it is about to fetch.

## Option 1 (default): use an existing database

Point `--predownloaded` at a DIAMOND database (`.dmnd`, or the folder containing `nr.dmnd`), and give the NCBI taxonomy files with `--names` and `--nodes`:

```
nextflow run main.nf -profile docker --proteins my_proteins.fa --predownloaded /shared/databases/nr.dmnd --names /shared/databases/names.dmp --nodes /shared/databases/nodes.dmp
```

Any `.dmnd` built with taxonomy works, including the `nr.dmnd` made by version 1 of this pipeline. On a cluster, the database just needs to be readable from the compute nodes; the containers mount it automatically, so a shared lab database works well.

If you don't have the taxonomy files, download them (~80 MB):

```
wget https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdmp.zip
unzip taxdmp.zip names.dmp nodes.dmp
```

`--predownloaded` also accepts an NCBI BLAST-format database folder, such as one downloaded by Option 2.

## Option 2: download NCBI nr (~800 GB)

Only if you have no database, add `--downloaddb_800GB`. The pipeline then downloads the latest NCBI `nr` database and the NCBI taxonomy:

- It is ~393 GB to download (176 volumes) and ~755 GB once extracted, so you need **about 800 GB free**. Volumes are extracted one at a time, so you never need room for the archives and the extracted database at once.
- It can take up to a day, depending on your internet speed.
- Do not try this with Gitpod.

NCBI no longer publishes an up-to-date nr FASTA (the last one is from February 2024), only the BLAST-format database. So that is what the pipeline downloads, and DIAMOND searches it directly without converting it to a `.dmnd`.

To download a different NCBI protein database, add its name with `--blast_db`, for example `--downloaddb_800GB --blast_db swissprot` (see https://ftp.ncbi.nlm.nih.gov/blast/db/ for the list). Smaller databases need far less space than nr.

The downloaded database is saved in `results/database/`:

```
results/database/blastdb/    the NCBI BLAST database (nr.*)
results/database/names.dmp   NCBI taxonomy names
results/database/nodes.dmp   NCBI taxonomy nodes
```

These are hard links to the files in the `work` directory, so they take no extra space. Move the `database` folder somewhere permanent (e.g. `blast_database`), then use it with Option 1 on later runs, so you never download it twice:

```
nextflow run main.nf -profile docker --proteins my_proteins.fa --predownloaded blast_database/blastdb --names blast_database/names.dmp --nodes blast_database/nodes.dmp
```

If you used `--blast_db` for the download, pass the same `--blast_db` again. If the hard links could not be made (for example when `work` and `results` are on different file systems), Nextflow prints a warning and you can find the same files in the `work` directory of the `DOWNLOAD` task instead.

# Test the pipeline

Before a big run, check everything works on your system with the built-in test. It downloads the small NCBI Swiss-Prot database (~225 MB, not nr) and runs every step on `Example.fasta`. It takes a few minutes:

```
nextflow run main.nf -profile test,docker
```

Results are written to `results_test/`. Add `--search_tool blastp` or `--search_tool blastn` to test NCBI BLAST instead. The blastn test downloads the small RefSeq Select RNA database (~0.1 GB, human and mouse only), so `Example.fasta` gets very few hits: it checks the steps run, not the biology.

# Search tool

Choose how sequences are searched with `--search_tool`:

| `--search_tool` | Input | Database | Notes |
|-----------------|-------|----------|-------|
| `diamond` (default) | `--proteins`, or `--nucleotide` (translated with TransDecoder) | DIAMOND `.dmnd`, or an NCBI BLAST protein database (default `nr`) | Much faster than NCBI blastp. |
| `blastp` | `--proteins`, or `--nucleotide` (translated with TransDecoder) | NCBI BLAST protein database folder (default `nr`) | NCBI BLAST+ blastp. Much slower than diamond: a large protein set against all of nr can take days. |
| `blastn` | `--nucleotide` only (longest transcript per gene, not translated) | NCBI BLAST nucleotide database folder (default `core_nt`) | NCBI BLAST+ blastn (megablast), best for close matches. |

NCBI BLAST needs a BLAST-format database folder (from Option 2 or NCBI), not a `.dmnd`. All three tools produce the same output columns, so the taxonomy results are made the same way. With NCBI BLAST, a `--numhits` below 5 makes BLAST print the warning "Examining 5 or more matches is recommended"; this is expected.

NCBI BLAST steps may run for up to 48 h (limited by `--max_time`). For bigger jobs, raise `--max_time`, or split your input into several fasta files, which are searched in parallel.

# Running the workflow on your data

The basic command to run this workflow is the following:
```
nextflow run main.nf -bg -resume -profile docker --nucleotide Example.fasta --nucl_type basic --predownloaded /path/to/nr.dmnd --names /path/to/names.dmp --nodes /path/to/nodes.dmp
```

This will run the whole pipeline on the (`--nucleotide`) file `Example.fasta` against your existing `nr.dmnd`, using the docker profile, so you must have docker installed. `-bg` allows Nextflow to run in the background, so you can continue in the same terminal and `-resume` allows Nextflow to continue from the last working step in the pipeline.

On a Sun Grid Engine cluster, swap `-profile docker` for your cluster profile, e.g. `-profile myriad`.

## Contamination check

Add `--expected_taxon` with the taxon you sequenced, as an NCBI scientific name or taxid (e.g. `--expected_taxon Insecta`, or `--expected_taxon 50557`). The report then shows how many top hits are within that taxon, and groups those outside it by domain and phylum, so bacterial or fungal contamination stands out. The top hits outside it are listed in `Taxo_summary/*_outside_expected_taxon.tsv`.

Pick a broad enough taxon (e.g. the class or order): genes whose closest relative in the database is outside your taxon will also show up as outside. For example, honeybee genes searched against Swiss-Prot often hit human or mouse, because Swiss-Prot has few bee proteins.

# All possible flags

| Flag | Default | Description |
|------|---------|-------------|
| `--proteins` | | Protein fasta file(s) to search. |
| `--nucleotide` | | Nucleotide transcript fasta file(s), translated with TransDecoder. |
| `--nucl_type` | `trinity` | Header format of `--nucleotide` files: `trinity`, `ensembl` or `basic`. |
| `--predownloaded` | | An existing database: a DIAMOND `.dmnd` file (or the folder containing `nr.dmnd`), or an NCBI BLAST database folder. |
| `--downloaddb_800GB` | | Download the NCBI nr database instead (~393 GB download, ~755 GB on disk; core_nt with `--search_tool blastn`). Off unless you add it. |
| `--search_tool` | `diamond` | `diamond`, `blastp` (NCBI BLAST+) or `blastn` (NCBI BLAST+, nucleotide input). See [Search tool](#search-tool). |
| `--blast_db` | `nr` (`core_nt` for blastn) | Which NCBI database `--downloaddb_800GB` downloads, or the database name inside a `--predownloaded` folder. |
| `--names` | | `names.dmp` taxonomy file (needed with `--predownloaded`). |
| `--nodes` | | `nodes.dmp` taxonomy file (needed with `--predownloaded`). |
| `--numhits` | `100` | Number of blast hits to keep per sequence (`--max-target-seqs` / `-max_target_seqs`). The taxonomy plots and report use each sequence's best hit (lowest e-value). |
| `--tophits` | | Diamond only. Instead of `--numhits`, keep all hits within this percentage of the best hit's score (diamond `--top`). |
| `--sensitivity` | `fast` | Diamond only. Sensitivity mode, e.g. `fast`, `sensitive`, `more-sensitive`, `ultra-sensitive`. |
| `--expected_taxon` | | The taxon you sequenced (NCBI name or taxid), for the [contamination check](#contamination-check). |
| `--outdir` | `results` | Output folder. |
| `--max_cpus` | `4` | Most CPUs any single step may use. |
| `--max_memory` | `32.GB` | Most memory any single step may use. Lower this if your machine has less memory, e.g. `--max_memory 12.GB`. |
| `--max_time` | `48.h` | Longest any single step may run. |

To set any of these, use `--` then the parameter name on the command line, e.g. `--outdir "My_results_folder"`.

# Results

Once completed, the results folder (`results/` unless you set `--outdir`) contains:

- `report/Protein_blast_and_taxonomy_multiqc_report.html`: **start here.** A report of the whole run: the database and software versions used, how many sequences found a hit, how similar and complete the top hits are, the contamination check (with `--expected_taxon`), and the taxonomy of the top hits.
- `Blast_results/`: the blast hits for each input file.
- `Taxo_figure/` and `Taxo_summary/`: pie charts and tables of the taxonomy of each sequence's top hit.
- `Prot/` or `Nucl/`: the sequences searched, when the input is nucleotides.
- `database/`: the downloaded database (with `--downloaddb_800GB`).
- `pipeline_info/`: the software versions used.

Every file, and every column of the blast results, is described in [docs/output.md](docs/output.md). A copy is saved in the results folder as `README.md`.

# Software

All tools run in pinned containers:

| Tool | Version | Container |
|------|---------|-----------|
| DIAMOND | 2.2.8 | `quay.io/biocontainers/diamond:2.2.8--he361c42_0` |
| TransDecoder | 5.7.1 | `quay.io/biocontainers/transdecoder:5.7.1--pl5321hdfd78af_2` |
| BLAST+ (database download, blastp, blastn) | 2.17.0 | `quay.io/biocontainers/blast:2.17.0--hb02a186_1` |
| R / Perl (taxonomy plots) | 4.6.1 | `rocker/r-ver:4.6.1` |
| MultiQC (report) | 1.35 | `quay.io/biocontainers/multiqc:1.35--pyhdfd78af_2` |

Please cite DIAMOND (Buchfink, Reuter & Drost, Nature Methods 2021) or BLAST+ (Camacho et al., BMC Bioinformatics 2009), MultiQC (Ewels et al., Bioinformatics 2016), and TransDecoder (https://github.com/TransDecoder/TransDecoder, as it is not in a journal).
