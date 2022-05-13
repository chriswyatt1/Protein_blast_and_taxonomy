# Protein_blast_and_taxonomy

Nextflow pipeline to run diamond blast and retrieve family level names for each protein.

# Pre-requisites

- You must be on a unix machine (mac, linux etc.) or cluster, with Nextflow installed (https://www.nextflow.io/docs/latest/getstarted.html). 
- Then you must have Docker installed on your machine (https://docs.docker.com/get-docker/; then login), if using the Docker config, or singularity installed if on a SunGrid Engine cluster.
- You must have at least 100GB of space to run this workflow, as the blast DB is this size.

# Setting up

First, if you have proteins (one per gene) alredy, you can run with the -protein flag. If you have nucleotide fasta IDs, you need to use the -nucleotide flag , which will find the unique proteins (longest per gene).

Next, you need to choose your environment profile. The two currently avialable are for a local Docker run, if local and must have docker installed on your machine (then use `-profile docker` in the script). OR, if you are running on a SunGrid Engine cluster, you can use the Myriad profile (which is a UCL custom config file for running on a specific sge cluster in UCL), use with `-profile myriad`.

The final consideration is where you have the NCBI blast database. If you plan to run multiple times its best to run this pipeline once, then move these large files somewhere on yourfile system and point to them in subsequent runs (is around 100GB,,,,so be careful)... This script will download and set up a blast database with every run, which is computationally expensive and a large time delay for each run (and will quickly fill up your system with multiple blast databases which can be huge, 100s of GBs). For this reason,,, do not try this workflow with Gitpod (max 30GB).

# Running the workflow on your data

The basic command to run this workflow is the following:
```
nextflow run main.nf -bg -resume -profile docker --nucleotide 'Example.fasta'
```

This will run the whole pipeline on the (--nucleotide) file `Example.fasta`, using the docker profile, so you must have docker installed, `-bg` allows Nextflow to run in the background, so you can continue in the same terminal and `-resume` allows Nextflow to continue from the last working step in the pipeline. 

WARNING: This pipeline could take up to a day depending on your internet speed etc. So is best to just leave it running in the background, while you do other things. If it takes longer, there may be an issue. Please create a new issue and let me know.

Once you have run this for the first time, you should be able to find three key database files in the `work` directory of this run. Look for the hash key for the `DOWNLOAD`, there should be a key such as `\[11/9bd97d\] Submitted process > DOWNLOAD`(NOTE, your random hex code will be different),,,, with this you should be able to find the blast files, in ./work/11/9bd97d.............  (the dot stand for unknown rets of key, press tab to complete path, and in the folder, you should find: `nr.dmnd` `names.dmp` `nodes.dmp`. These you can now feed into the pipeline to prevent a repeat of the download step. I would download them into their own folder, called say `blast_database`

With the locations of these files set, you can then run the pipeline a second time using these input files, as so:

```
nextflow run main.nf -bg -resume -profile docker --nucleotide Example.fasta --predownloaded blast_database/nr.dmnd --names blast_database/names.dmp --nodes results/nodes.dmp
```

By default the total number of hits per sequence is set to 1. You can change this with the flag `--numhits <NUMBER>`. 

# Results

Once completed, you should have a folder called `Results`, which contains the blast hits file in tab format, along with some PDF overviews of the taxonomy information of all the genes.


# ADMIN Section
For testing blast etc, ():
We can use the official diamond docker call:

docker pull buchfink/diamond:v2.0.13

Then run as docker run -it --rm buchfink/diamond 

Test on docker:
docker run -it --entrypoint /bin/bash --volume $PWD/Human_olfactory.fasta:/Human_olfactory.fasta buchfink/diamond 

Replicate error with singularity on UCL cluster :
singularity exec /your/dir/Scratch/.singularity/pull/buchfink-diamond.img /bin/bash -c "diamond makedb --in nr.gz -d database"


This pipeline uses trandecoder is you supply Trinity.fasta output, in order to get the likely coding regions of each gene. This uses TransDecoder Release v5.5.0. Make sure to cite the webpage : https://github.com/TransDecoder/TransDecoder (As it is not in a journal)
