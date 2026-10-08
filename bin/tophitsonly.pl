#!/usr/bin/perl
#tophitsonly.pl
use strict;
use warnings;

#Keeps the best hit for each query: the one with the lowest e-value (column 5). Diamond and blast list
#each query's hits best first, so on a tie the first listed is kept. (Picking the highest percent identity
#instead favours short, partial matches when several hits are kept per query.)
die "Please specify (1) Blast hits\n" unless(@ARGV==1);


my $input = $ARGV[0];

my $OUT_file="tophitsonly.tsv";

open(my $INPUT_IN, "<", $input)   or die "Could not open $input \n";
open(my $outhandle, ">", $OUT_file)   or die "Could not open $OUT_file\n";

my %genes;
my %best_evalue;

while (my $line=<$INPUT_IN>){
	chomp $line;
	my @split= split("\t", $line);

	my $id= $split[0];
	my $evalue= $split[4];

	if (!exists $genes{$id} || $evalue < $best_evalue{$id}){
		$genes{$id}="$line";
		$best_evalue{$id}=$evalue;
	}
}

foreach my $key ( sort keys %genes){

	print $outhandle "$genes{$key}\n";

}
