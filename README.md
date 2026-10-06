# Protein_blast_and_taxonomy

Nextflow pipeline to run diamond blast and retrieve family level names for each protein.

Version 2 brings the pipeline up to date with Nextflow 26 and current NCBI data. See [CHANGELOG.md](CHANGELOG.md) for what changed from v1.

# Pre-requisites

- You must be on a unix machine (mac, linux etc.) or cluster.
- Nextflow 25.04 or newer (https://www.nextflow.io/docs/latest/getstarted.html). Tested on Nextflow 26.04.
- LOCAL: requires Docker (https://docs.docker.com/get-docker/). On Apple Silicon Macs the containers run under Docker's x86 emulation, which works but is slow for large searches.
- SUN GRID ENGINE CLUSTER: requires Singularity or Apptainer. Normally already on the HPC Sun Grid Engine clusters.
- Disk space for the database. The default NCBI `nr` database is currently ~393 GB to download (176 volumes) and ~755 GB once extracted, so you need **about 800 GB free** for the download step. Volumes are extracted one at a time, so you never need room for the archives and the extracted database at once. Smaller databases such as `swissprot` (~1 GB) need far less.
- Git (optional) (https://github.com/git-guides/install-git). So you can git clone the repo.

# Setting up

First, you need to clone the repository from github `git clone https://github.com/chriswyatt1/Protein_blast_and_taxonomy.git`, if you have git installed, OR download the zip folder from `https://github.com/chriswyatt1/Protein_blast_and_taxonomy`, then unzip it and `cd` into this directory.

Second, if you have proteins (one per gene) already, you can run with the `--proteins` flag. If you have nucleotide transcripts, use the `--nucleotide` flag, which keeps the longest transcript per gene and finds the open reading frames with TransDecoder. Tell the pipeline how your fasta headers are formatted with `--nucl_type`:

- `trinity` (default): Trinity headers such as `TRINITY_DN1000_c0_g1_i1`. The isoform suffix (`_i1`) is removed to group isoforms into genes.
- `ensembl`: Ensembl cDNA headers, grouped by the gene ID after the first `:`.
- `basic`: any other headers. Every sequence is kept as its own gene (this is what `Example.fasta` needs).

Third, you need to choose your environment profile. Use `-profile docker` for a local run with Docker, `-profile myriad` for UCL's Myriad cluster, `-profile cscluster` for the UCL CS cluster, or `-profile apptainer` for Apptainer.

The final consideration is the blast database. By default the pipeline downloads the latest NCBI `nr` protein database together with the NCBI taxonomy, which takes a long time (up to a day depending on your internet speed). The database is saved into `results/database/` so you only need to do this once; see [Reusing the database](#reusing-the-database). Because of its size, do not try this workflow with Gitpod.

# Test the pipeline

Before a big run, check everything works on your system with the built-in test. It downloads the small NCBI Swiss-Prot database (~225 MB) instead of nr and runs every step on `Example.fasta`. It takes a few minutes:

```
nextflow run main.nf -profile test,docker
```

Results are written to `results_test/`.

# Running the workflow on your data

The basic command to run this workflow is the following:
```
nextflow run main.nf -bg -resume -profile docker --nucleotide Example.fasta --nucl_type basic
```

This will run the whole pipeline on the (`--nucleotide`) file `Example.fasta`, using the docker profile, so you must have docker installed. `-bg` allows Nextflow to run in the background, so you can continue in the same terminal and `-resume` allows Nextflow to continue from the last working step in the pipeline.

WARNING: The nr download could take up to a day depending on your internet speed etc. So it is best to just leave it running in the background, while you do other things. If it takes longer, there may be an issue. Please create a new issue and let me know.

To search a different NCBI protein database, give its name with `--blast_db`, for example `--blast_db swissprot` or `--blast_db refseq_protein` (see https://ftp.ncbi.nlm.nih.gov/blast/db/ for the list).

# Reusing the database

Once you have run the pipeline once, the downloaded database is in `results/database/`:

```
results/database/blastdb/    the NCBI BLAST database (nr.*)
results/database/names.dmp   NCBI taxonomy names
results/database/nodes.dmp   NCBI taxonomy nodes
```

These are hard links to the files in the `work` directory, so they take no extra space. Move the `database` folder somewhere permanent (e.g. `blast_database`), then point to it on later runs to skip the download:

```
nextflow run main.nf -bg -resume -profile docker --nucleotide Example.fasta --nucl_type basic --predownloaded blast_database/blastdb --names blast_database/names.dmp --nodes blast_database/nodes.dmp
```

If you used `--blast_db` to download a different database, pass the same `--blast_db` again.

If the hard links could not be made (for example when `work` and `results` are on different file systems), Nextflow prints a warning and you can find the same files in the `work` directory of the `DOWNLOAD` task instead.

`--predownloaded` also accepts a diamond database file (`.dmnd`), such as the `nr.dmnd` made by version 1 of this pipeline:

```
nextflow run main.nf -profile docker --proteins my_proteins.fa --predownloaded blast_database/nr.dmnd --names blast_database/names.dmp --nodes blast_database/nodes.dmp
```

# All possible flags

| Flag | Default | Description |
|------|---------|-------------|
| `--proteins` | | Protein fasta file(s) to search. |
| `--nucleotide` | | Nucleotide transcript fasta file(s), translated with TransDecoder. |
| `--nucl_type` | `trinity` | Header format of `--nucleotide` files: `trinity`, `ensembl` or `basic`. |
| `--blast_db` | `nr` | NCBI BLAST protein database to download (or the name of the database in `--predownloaded`). |
| `--predownloaded` | | An existing database: a BLAST database directory or a diamond `.dmnd` file. |
| `--names` | | `names.dmp` taxonomy file (needed with `--predownloaded`). |
| `--nodes` | | `nodes.dmp` taxonomy file (needed with `--predownloaded`). |
| `--numhits` | `1` | Number of blast hits to keep per sequence (diamond `--max-target-seqs`). |
| `--tophits` | | Instead of `--numhits`, keep all hits within this percentage of the best hit's score (diamond `--top`). |
| `--sensitivity` | `fast` | Diamond sensitivity mode, e.g. `fast`, `sensitive`, `more-sensitive`, `ultra-sensitive`. |
| `--outdir` | `results` | Output folder. |
| `--max_cpus` | `4` | Most CPUs any single step may use. |
| `--max_memory` | `32.GB` | Most memory any single step may use. Lower this if your machine has less memory, e.g. `--max_memory 12.GB`. |
| `--max_time` | `48.h` | Longest any single step may run. |

To set any of these, use `--` then the parameter name on the command line, e.g. `--outdir "My_results_folder"`.

# Results

Once completed, you should have a folder called `results`, which contains:

- `Blast_results/`: the diamond hits for each input file in tab format (`*_results.tsv`, columns: query, subject, subject title, percent identity, e-value, subject phylum, subject taxonomy id) and the best hit per query (`*_top.tsv`).
- `Taxo_figure/`: a PDF of pie charts summarising the taxonomy of the best hits at each rank (kingdom to subspecies).
- `Taxo_summary/`: the counts behind each pie chart (`*_top.tsv_<rank>`), plus a per-gene summary of the phyla hit (`*_summary.tsv`).
- `Prot/`: the proteins predicted by TransDecoder (only with `--nucleotide`).
- `database/`: the downloaded database (only when not using `--predownloaded`).


# Software

All tools run in pinned containers:

| Tool | Version | Container |
|------|---------|-----------|
| DIAMOND | 2.2.8 | `quay.io/biocontainers/diamond:2.2.8--he361c42_0` |
| TransDecoder | 5.7.1 | `quay.io/biocontainers/transdecoder:5.7.1--pl5321hdfd78af_2` |
| BLAST+ (database download) | 2.17.0 | `quay.io/biocontainers/blast:2.17.0--hb02a186_1` |
| R / Perl (taxonomy plots) | 4.6.1 | `rocker/r-ver:4.6.1` |

Please cite DIAMOND (Buchfink, Reuter & Drost, Nature Methods 2021) and TransDecoder (https://github.com/TransDecoder/TransDecoder, as it is not in a journal).
