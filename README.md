# Protein_blast_and_taxonomy
Nextflow pipeline to retrieve family level names for each protein


We can use the official diamond docker call:

docker pull buchfink/diamond:v2.0.13

Then run as docker run -it --rm buchfink/diamond 

Test on docker:
docker run -it --entrypoint /bin/bash --volume $PWD/Human_olfactory.fasta:/Human_olfactory.fasta buchfink/diamond 

Replicate error with singularity on UCL cluster :
singularity exec /your/dir/Scratch/.singularity/pull/buchfink-diamond.img /bin/bash -c "diamond makedb --in nr.gz -d database"


This pipeline uses trandecoder is you supply Trinity.fasta output, in order to get the likely coding regions of each gene. This uses TransDecoder Release v5.5.0. Make sure to cite the webpage : https://github.com/TransDecoder/TransDecoder (As it is not in a journal)
