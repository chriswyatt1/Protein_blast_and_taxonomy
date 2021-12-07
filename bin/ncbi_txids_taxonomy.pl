#!/usr/bin/perl
#plot_event.pl
use strict;
use warnings;

die "Please specify (1) nodes.dmp (2) names.dmp (3) NCBI Ids (new line sep. Reads last column in file input) (4) Level to summarise (e.g. Family)\n" unless(@ARGV==4);


my $nodes = $ARGV[0];
my $names = $ARGV[1];
my $input = $ARGV[2];
my $level = $ARGV[3];

my $OUT_file="TAXONOMY_processed.tsv";

#initiaite groups from conversion file.
open(my $NODE_IN, "<", $nodes)   or die "Could not open $nodes \n";
open(my $NAME_IN, "<", $names)   or die "Could not open $names \n";
open(my $INPUT_IN, "<", $input)   or die "Could not open $input \n";

open(my $outhandle, ">", $OUT_file)   or die "Could not open $OUT_file\n";

my @FULL_TABLE;

my %node_hash_parent;
my %node_hash_order;

while (my $line=<$NODE_IN>){
	chomp $line;
	my @linesplit=split(' ', $line);
	$node_hash_parent{$linesplit[0]}=$linesplit[2];
	$node_hash_order{$linesplit[0]}=$linesplit[4];
}


my %name_hash;

while (my $line=<$NAME_IN>){
	chomp $line;
	my @linesplit=split(' ', $line);
	#if line includes the sceintific name then add id to name to hash.
	if ($line =~ m/scientific name/g ){
		$name_hash{$linesplit[0]}=$linesplit[2];
	}	
}

my @array_res;

while (my $line=<$INPUT_IN>){
	chomp $line;
	my @sp1= split("\t", $line);
	my @sp2= split("\;", $sp1[-1]);
	my $id= $sp2[0];

	#Set id for first loop
	my $parent_id=$id;
	my $parent_fam=$id;
	#Set result variable 
	my $result;
	#Set if found hit.
	my $hit=0;

	do {
		
		$parent_id = $node_hash_parent{$parent_id};
		$parent_fam= $node_hash_order{$parent_id};
		if ( $parent_fam eq "$level"){
			print $outhandle "$name_hash{$parent_id}\n";
			push (@array_res, "$name_hash{$parent_id}");
			$hit=1;
		}
		#When parent id is 1, this mean root of all organisms
		if ( $parent_id == 1 ){
			if ($hit){
				#Do nothing, already hit.
			}
			else{
				#Add to db, a hit without element of level.
				print $outhandle "No_family\n";
				push (@array_res, "No_family");
			}
		}
	}
	until($parent_id == 1);
}

my $merge_ids=join("\"\,\"", @array_res);

my $RCOMMAND="ACTUAL_R_CODE";
open(my $out_Rcmds,   "> $RCOMMAND")  or die "error opening $RCOMMAND. $!";

print $out_Rcmds "data=c(\"$merge_ids\");\n";
print $out_Rcmds "pdf(\"Res_$input\_$level\.pdf\", height=4, width=4, useDingbats=F)\n";
print $out_Rcmds "pie(table(data), names(table(data)))\n";
print $out_Rcmds "dev.off()\n";

`R --vanilla <ACTUAL_R_CODE> output.ofthis.test`;

