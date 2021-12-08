#!/usr/bin/perl
#plot_event.pl
use strict;
use warnings;

die "Please specify (1) nodes.dmp (2) names.dmp (3) NCBI Ids (new line sep. Reads last column in file input)\n" unless(@ARGV==3);


my $nodes = $ARGV[0];
my $names = $ARGV[1];
my $input = $ARGV[2];

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


my @array_kingdom;
my @array_phylum;
my @array_class;
my @array_order;
my @array_family;
my @array_genus;
my @array_species;

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

	do {
		
		$parent_id = $node_hash_parent{$parent_id};
		$parent_fam= $node_hash_order{$parent_id};

		if ( $parent_fam eq "kingdom"){
			push (@array_kingdom, "$name_hash{$parent_id}");
		}
		elsif ($parent_fam eq "phylum"){
			push (@array_phylum, "$name_hash{$parent_id}");
		}
		elsif ($parent_fam eq "class"){
			push (@array_class, "$name_hash{$parent_id}");
		}
		elsif ($parent_fam eq "family"){
			push (@array_family, "$name_hash{$parent_id}");
		}
		elsif ($parent_fam eq "genus"){
			push (@array_genus, "$name_hash{$parent_id}");
		}
		elsif ($parent_fam eq "species"){
			push (@array_species, "$name_hash{$parent_id}");
		}
		else{
			#Do nothing. Though could be a source of error to check in future.
		}

	}
	until($parent_id == 1);
}

#Merge layers
my $kingdom=join("\"\,\"", @array_kingdom);
my $phylum=join("\"\,\"", @array_phylum);
my $class=join("\"\,\"", @array_class);
my $order=join("\"\,\"", @array_order);
my $family=join("\"\,\"", @array_family);
my $genus=join("\"\,\"", @array_genus);
my $species=join("\"\,\"", @array_species);

my $merge_kingdom=join("\"\,\"", @array_kingdom);

my $RCOMMAND="ACTUAL_R_CODE";
open(my $out_Rcmds,   "> $RCOMMAND")  or die "error opening $RCOMMAND. $!";

print $out_Rcmds "data_kingdom=c(\"$merge_kingdom\");\n";
print $out_Rcmds "data_phylum=c(\"$merge_phylum\");\n";
print $out_Rcmds "data_class=c(\"$merge_class\");\n";
print $out_Rcmds "data_order=c(\"$merge_order\");\n";
print $out_Rcmds "data_family=c(\"$merge_family\");\n";
print $out_Rcmds "data_genus=c(\"$merge_genus\");\n";
print $out_Rcmds "data_species=c(\"$merge_species\");\n";

print $out_Rcmds "pdf(\"Res_$input\_complete\.pdf\", paper=\"a4\" , useDingbats=F)\n";
print $out_Rcmds "par(mfrow = c(2,4))\n";
print $out_Rcmds "pie(table(data_kingdom), names(table(data_kingdom)))\n";
print $out_Rcmds "pie(table(data_phylum), names(table(data_phylum)))\n";
print $out_Rcmds "pie(table(data_class), names(table(data_class)))\n";
print $out_Rcmds "pie(table(data_order), names(table(data_order)))\n";
print $out_Rcmds "pie(table(data_family), names(table(data_family)))\n";
print $out_Rcmds "pie(table(data_genus), names(table(data_genus)))\n";
print $out_Rcmds "pie(table(data_species), names(table(data_species)))\n";

print $out_Rcmds "dev.off()\n";

`R --vanilla <ACTUAL_R_CODE> output.ofthis.test`;
