# Protein_blast_and_taxonomy
Nextflow pipeline to retrieve family level names for each protein


We can use the official diamond docker call:

docker pull buchfink/diamond:v2.0.13

Then run as docker run -it --rm buchfink/diamond 

Test on docker:
docker run -it --entrypoint /bin/bash --volume $PWD/Human_olfactory.fasta:/Human_olfactory.fasta buchfink/diamond 

Replicate error with singularity on UCL cluster :
singularity exec /your/dir/Scratch/.singularity/pull/buchfink-diamond.img /bin/bash -c "diamond makedb --in nr.gz -d database"
