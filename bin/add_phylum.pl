#!/usr/bin/env perl
#add_phylum.pl
use strict;
use warnings;

#Adds the phylum of each hit (like diamond's sphylums) as the sixth column of NCBI blast output
#(qseqid sseqid stitle pident evalue qcovhsp staxids), so it matches the diamond output used by the
#rest of the pipeline: qseqid sseqid stitle pident evalue sphylums qcovhsp staxids.
die "Please specify (1) nodes.dmp (2) names.dmp (3) Blast hits (tab format, taxids in the last column)\n" unless(@ARGV==3);

my $nodes = $ARGV[0];
my $names = $ARGV[1];
my $input = $ARGV[2];

open(my $NODE_IN, "<", $nodes)   or die "Could not open $nodes \n";
open(my $NAME_IN, "<", $names)   or die "Could not open $names \n";
open(my $INPUT_IN, "<", $input)   or die "Could not open $input \n";

my %node_hash_parent;
my %node_hash_order;

while (my $line=<$NODE_IN>){
	chomp $line;
	#Split on the dmp field separator, as ranks can contain spaces (e.g. "species group")
	my @linesplit=split(/\t\|\t/, $line);
	$node_hash_parent{$linesplit[0]}=$linesplit[1];
	$node_hash_order{$linesplit[0]}=$linesplit[2];
}

#Only the names of phyla are needed
my %phylum_name;

while (my $line=<$NAME_IN>){
	next unless ($line =~ m/\tscientific name\t/);
	my @linesplit=split(/\t\|\t/, $line);
	if (exists $node_hash_order{$linesplit[0]} && $node_hash_order{$linesplit[0]} eq "phylum"){
		$phylum_name{$linesplit[0]}=$linesplit[1];
	}
}

while (my $line=<$INPUT_IN>){
	chomp $line;
	my @split= split("\t", $line, -1);
	my $taxids= $split[-1];

	#Walk up from each taxid (several are separated by ";") to its phylum
	my @phyla;
	my %seen;
	foreach my $id (split("\;", $taxids)){
		my $steps=0;
		while (exists $node_hash_order{$id} && $node_hash_order{$id} ne "phylum" && $id ne "1" && $steps < 100){
			$id = $node_hash_parent{$id};
			$steps++;
		}
		if (exists $phylum_name{$id} && !$seen{$id}){
			push (@phyla, $phylum_name{$id});
			$seen{$id}=1;
		}
	}
	my $phylum = @phyla ? join("\;", @phyla) : "N/A";

	splice(@split, 5, 0, $phylum);
	print join("\t", @split), "\n";
}
