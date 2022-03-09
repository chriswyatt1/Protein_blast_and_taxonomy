process SPLIT_FASTA {
    label 'split_fasta'
    input:
        path sequences

    output:
        path ('myseq*') , emit: split_seqs

    script:
    """
	awk 'BEGIN {n_seq=0;} /^>/ {if(n_seq%100==0){file=sprintf("myseq%d.fa",n_seq);} print >> file; n_seq++; next;} { print >> file; }' < ${sequences}

    """
} 

