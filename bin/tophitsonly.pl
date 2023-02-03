#!/usr/bin/perl
#plot_event.pl
use strict;
use warnings;

die "Please specify (1) Blast hits\n" unless(@ARGV==1);


my $input = $ARGV[0];

my $OUT_file="tophitsonly.tsv";

#initiaite groups from conversion file.
open(my $INPUT_IN, "<", $input)   or die "Could not open $input \n";
open(my $outhandle, ">", $OUT_file)   or die "Could not open $OUT_file\n";

my %genes;

while (my $line=<$INPUT_IN>){
	chomp $line;
	my @split= split("\t", $line);

	my $id= $split[0];
	my $perc= $split[3];

	if ($genes{$id}){
		my $oldline=$genes{$id};
		my @split2= split("\t", $oldline);

		if ($perc > $split2[3]){
			$genes{$id}="$line";
		}
		else{
			#do nothing.
		}
		
	}
	else{
		$genes{$id}="$line";
	}

}

foreach my $key ( sort keys %genes){

	print $outhandle "$genes{$key}\n";
	
}
