# Changelog

## v2.0.0 (2026-10-06)

### Breaking changes

- **Nextflow 25.04 or newer is required.** The pipeline now passes `nextflow lint` and runs on Nextflow 26, where the strict syntax parser is the default (v1 failed to parse its config on Nextflow 26).
- **The database is now NCBI's preformatted BLAST database (default `nr`) instead of `nr.gz`.** NCBI stopped updating the `nr.gz` FASTA file in February 2024, so v1 always downloaded a stale database. DIAMOND 2.2 searches BLAST databases directly, so the `MAKE_DB` step and the `prot.accession2taxid` download are gone. Choose another NCBI database with `--blast_db`.
- `--max_cpus`, `--max_memory` and `--max_time` now cap every step (using Nextflow's `resourceLimits`, which replaces the `check_max` function). The `myriad` and `cscluster` profiles raise the caps to keep their v1 resources.
- All containers changed (see below). Profile configs no longer set containers; each module pins its own.

### Fixed

- v1 could no longer build a database from current NCBI data: DIAMOND 2.0.13 rejects the `domain` rank NCBI added to the taxonomy in 2025 ("Invalid taxonomic rank: domain").
- `names.dmp` and `nodes.dmp` were swapped when the database was downloaded, so the taxonomy pie charts came out empty.
- The blast step used `--top $params.tophits`, which was undefined, so diamond got `--top null`. `--numhits` works again, and `--tophits` is now a real option.
- The top-hit (`*_top.tsv`) and per-gene summary (`*_summary.tsv`) files were never published to `results/`.
- Species and subspecies counts were inflated because ranks with spaces (e.g. "species group") were cut to "species" when reading `nodes.dmp`.
- Running without `--proteins` or `--nucleotide` now stops with a clear error; `--predownloaded` without `--names`/`--nodes` also errors straight away.
- README: the example command now uses `--nucl_type basic`. With the default `trinity`, `Example.fasta` collapsed from 560 transcripts to 5 "genes".

### Updated

- DIAMOND 2.0.13 → 2.2.8 (`quay.io/biocontainers/diamond`). Existing `.dmnd` databases built by v1 still work with `--predownloaded`.
- TransDecoder 5.5.0 (copied into `bin/`) → 5.7.1 (`quay.io/biocontainers/transdecoder`). Predicted proteins are identical on `Example.fasta`.
- R 4.1.0 → 4.6.1 (`rocker/r-ver`, which has native arm64 images).
- Database download uses the BLAST+ 2.17.0 container, md5-checks every volume and extracts volumes one at a time to keep disk use down.

### Added

- `-profile test`: a quick end-to-end run on the NCBI Swiss-Prot database.
- The downloaded database is published to `results/database/` (as hard links) so it is easy to reuse with `--predownloaded`.
- The per-rank taxonomy count tables are published to `results/Taxo_summary/`.

### Removed

- `modules/make_blast_db.nf`, the copied TransDecoder code (`bin/TransDecoder.LongOrfs`, `bin/util/`) and the `docker/` build files for the old images.
