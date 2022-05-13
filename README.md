# Protein_blast_and_taxonomy
Nextflow pipeline to run diamond blast and retrieve family level names for each protein

# Setting up

First, if you have proteins (one per gene) alredy, you can run with the -protein flag. If you have nucleotide fasta IDs, you need to use the -nucleotide flag , which will find the unique proteins (longest per gene).

Next, you need to choose your environment profile. The two currently avialable are for a local Docker run, if local and must have docker installed on your machine (then use `-profile docker` in the script). OR, if you are running on a SunGrid Engine cluster, you can use the Myriad profile (which is a UCL custom config file for running on a specific sge cluster in UCL), use with `-profile myriad`.

The final consideration is where you have the NCBI blast database. If you plan to run mutliple times its best to run this pipeline once, then move these large files somewhere on yourfile system and point to them in subsequent runs... Else this script will download and set up a blast database with every run, which is computationally expensive and a large time delay for each run (and will quickly fill up your system with multiple blast databases which can be huge (100s of GB)

# Running the workflow on your data

The basic command to run this workflow is the following:
```
nextflow run main.nf -bg -resume -profile docker --nucleotide 'results/Input_Trinity_fasta/*.fasta'
```

This will run the whole pipeline on a series of fasta files (--nucleotide), in a folder called `results/Input_Trinity_fasta`, using the docker profile, so you must have docker installed, `-bg` allows Nextflow to run in the background, so you can continue in the same terminal and `-resume` allows Nextflow to continue from the last working step in the pipeline. 

Once you have run this for the first time, you should be able to find three key database files in the `work` directory of this run. Look for the hash key for the download , there should be a key such as a3/d2042340234,,,, with this you should be able to find the blast files, in ./work/a3/d2042340234.............  (the dot stand for unknown rets of key, press tab to complete path, and in the folder, you should find: `nr.dmnd` `names.dmp` `nodes.dmp`. These you can now feed into the pipeline to prevent a repeat of the download step.

With the locations of these files set, you can then run the pipeline a second time using these input files, as so:

```
nextflow run main.nf -bg -resume -profile docker --nucleotide 'results/Input_Trinity_fasta/*.fasta --predownloaded results/nr.dmnd --names results/names.dmp --nodes results/nodes.dmp '
```




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
