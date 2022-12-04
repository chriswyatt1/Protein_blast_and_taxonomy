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

#open(my $outhandle, ">", $OUT_file)   or die "Could not open $OUT_file\n";

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
	my @linesplit=split('\t|\t', $line);
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
my @array_subspecies;
my $line_c=0;
my @array_res;

while (my $line=<$INPUT_IN>){
	chomp $line;
	my @sp1= split("\t", $line);
	my @sp2= split("\;", $sp1[-1]);
	my $id= $sp2[0];

	#Set id for first loop
	my $parent_id=$id;
	#Set result variable 
	my $result;
	my $hits_c=0;
	if (exists $name_hash{$id}){
		do {
		
			my $current_id=$parent_id;
			my $current_fam=$node_hash_order{$current_id};

			if ( $current_fam eq "kingdom"){
				push (@array_kingdom, "$name_hash{$current_id}");
			}
			elsif ($current_fam eq "phylum"){
				push (@array_phylum, "$name_hash{$current_id}");
			}
			elsif ($current_fam eq "class"){
				push (@array_class, "$name_hash{$current_id}");
			}
			elsif ($current_fam eq "order"){
				push (@array_order, "$name_hash{$current_id}");
			}
			elsif ($current_fam eq "family"){
				push (@array_family, "$name_hash{$current_id}");
			}
			elsif ($current_fam eq "genus"){
				push (@array_genus, "$name_hash{$current_id}");
			}
			elsif ($current_fam eq "species"){
				push (@array_species, "$name_hash{$current_id}");
			}
			elsif ($current_fam eq "subspecies"){
				push (@array_subspecies, "$name_hash{$current_id}");
			}

			else{
				#print "This is an error on line $line_c : $current_id $current_fam  with $node_hash_parent{$parent_id}\n";
				#$parent_id = 1;
				#Do nothing. Though could be a source of error to check in future.
			}
			$parent_id = $node_hash_parent{$parent_id};
		}
		until($parent_id == 1);
		$line_c++;
	}
	else {
		print "An entry does not have a hit in the names.dmp. Skipping line $line_c : $id\n";
	}
}

#Merge layers
my $kingdom=join("\"\,\"", @array_kingdom);
my $phylum=join("\"\,\"", @array_phylum);
my $class=join("\"\,\"", @array_class);
my $order=join("\"\,\"", @array_order);
my $family=join("\"\,\"", @array_family);
my $genus=join("\"\,\"", @array_genus);
my $species=join("\"\,\"", @array_species);
my $subspecies=join("\"\,\"", @array_subspecies);

my $merge_kingdom=join("\"\,\"", @array_kingdom);

my $RCOMMAND="ACTUAL_R_CODE";
open(my $out_Rcmds,   "> $RCOMMAND")  or die "error opening $RCOMMAND. $!";

print $out_Rcmds "data_kingdom=c(\"$kingdom\");\n";
print $out_Rcmds "data_phylum=c(\"$phylum\");\n";
print $out_Rcmds "data_class=c(\"$class\");\n";
print $out_Rcmds "data_order=c(\"$order\");\n";
print $out_Rcmds "data_family=c(\"$family\");\n";
print $out_Rcmds "data_genus=c(\"$genus\");\n";
print $out_Rcmds "data_species=c(\"$species\");\n";
print $out_Rcmds "data_subspecies=c(\"$subspecies\");\n";

print $out_Rcmds "pdf(\"Res_$input\_complete\.pdf\", width=8 , height=16 , useDingbats=F)\n";
print $out_Rcmds "par(mfrow = c(4,2))\n";

print $out_Rcmds "
temp=names(table(data_kingdom))
temp2=table(data_kingdom)
temp[temp2 <  (length(data_kingdom))/100] <- NA
pie(main = c(\"Count\",length(data_kingdom)), temp2, temp )
write.table(sort(table(data_kingdom), decreasing = T),\"$input\_kingdom\", sep=\"\t\", quote=F)\n";

print $out_Rcmds "
temp=names(table(data_phylum))
temp2=table(data_phylum)
temp[temp2 <  (length(data_phylum))/100] <- NA
pie(main = c(\"Count\",length(data_phylum)), temp2, temp )
write.table(sort(table(data_phylum), decreasing = T),\"$input\_phylum\", sep=\"\t\", quote=F)\n";

print $out_Rcmds "
temp=names(table(data_class))
temp2=table(data_class)
temp[temp2 <  (length(data_class))/100] <- NA
pie(main = c(\"Count\",length(data_class)), temp2, temp )
write.table(sort(table(data_class), decreasing = T),\"$input\_class\", sep=\"\t\", quote=F)\n";

print $out_Rcmds "
temp=names(table(data_order))
temp2=table(data_order)
temp[temp2 <  (length(data_order))/100] <- NA
pie(main = c(\"Count\",length(data_order)), temp2, temp )
write.table(sort(table(data_order), decreasing = T),\"$input\_order\", sep=\"\t\", quote=F)\n";

print $out_Rcmds "
temp=names(table(data_family))
temp2=table(data_family)
temp[temp2 <  (length(data_family))/100] <- NA
pie(main = c(\"Count\",length(data_family)), temp2, temp )
write.table(sort(table(data_family), decreasing = T),\"$input\_family\", sep=\"\t\", quote=F)\n";

print $out_Rcmds "
temp=names(table(data_genus))
temp2=table(data_genus)
temp[temp2 <  (length(data_genus))/100] <- NA
pie(main = c(\"Count\",length(data_genus)), temp2, temp )
write.table(sort(table(data_genus), decreasing = T),\"$input\_genus\", sep=\"\t\", quote=F)\n";

print $out_Rcmds "
temp=names(table(data_species))
temp2=table(data_species)
temp[temp2 <  (length(data_species))/100] <- NA
pie(main = c(\"Count\",length(data_species)), temp2, temp )
write.table(sort(table(data_species), decreasing = T),\"$input\_species\", sep=\"\t\", quote=F)\n";

print $out_Rcmds "
temp=names(table(data_subspecies))
temp2=table(data_subspecies)
temp[temp2 <  (length(data_subspecies))/100] <- NA
pie(main = c(\"Count\",length(data_subspecies)), temp2, temp )
write.table(sort(table(data_subspecies), decreasing = T),\"$input\_subspecies\", sep=\"\t\", quote=F)\n";

print $out_Rcmds "dev.off()\n";

`R --vanilla <ACTUAL_R_CODE> output.ofthis.test`;

