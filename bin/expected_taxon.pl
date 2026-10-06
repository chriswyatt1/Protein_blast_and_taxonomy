#!/usr/bin/env perl
#expected_taxon.pl
use strict;
use warnings;

#Checks whether each query's top hit is within an expected taxon (e.g. the class or order of the species
#sequenced), to flag possible contamination. Top hits outside it are grouped by domain and phylum.
#Writes a MultiQC section, the counts for the search summary table, and the list of top hits outside.
die "Please specify (1) nodes.dmp (2) names.dmp (3) top hits (tophitsonly.pl output) (4) expected taxon (NCBI scientific name or taxid) (5) sample name\n" unless(@ARGV==5);

my $nodes = $ARGV[0];
my $names = $ARGV[1];
my $top = $ARGV[2];
my $expected = $ARGV[3];
my $sample = $ARGV[4];

open(my $NODE_IN, "<", $nodes)   or die "Could not open $nodes \n";
open(my $NAME_IN, "<", $names)   or die "Could not open $names \n";
open(my $TOP_IN, "<", $top)   or die "Could not open $top \n";

my %node_hash_parent;
my %node_hash_order;

while (my $line=<$NODE_IN>){
	chomp $line;
	#Split on the dmp field separator, as ranks can contain spaces (e.g. "species group")
	my @linesplit=split(/\t\|\t/, $line);
	$node_hash_parent{$linesplit[0]}=$linesplit[1];
	$node_hash_order{$linesplit[0]}=$linesplit[2];
}

#Domains are "domain" in current NCBI taxonomy, "superkingdom" in dumps before 2025, and viruses are an "acellular root"
my %label_rank= ("domain" => 1, "superkingdom" => 1, "acellular root" => 1, "phylum" => 1);

#Find the expected taxon (by taxid, or by scientific name ignoring case), and the names used for labels
my %expected_ids;
my %name_hash;
$expected_ids{$expected}=1 if ($expected =~ m/^\d+$/ && exists $node_hash_parent{$expected});
while (my $line=<$NAME_IN>){
	next unless ($line =~ m/\tscientific name\t/);
	my @linesplit=split(/\t\|\t/, $line);
	my $id= $linesplit[0];
	if (lc($linesplit[1]) eq lc($expected)){
		$expected_ids{$id}=1;
	}
	if ($expected_ids{$id} || (exists $node_hash_order{$id} && $label_rank{$node_hash_order{$id}})){
		$name_hash{$id}=$linesplit[1];
	}
}

my $display= join(" or ", map { "$name_hash{$_} (taxid $_)" } sort { $a <=> $b } keys %expected_ids);

#Expected taxon not in the taxonomy: say so in the report, rather than failing the run
if (!%expected_ids){
	open(my $HTML_OUT, ">", "$sample\_expected_taxon_mqc.html")   or die "Could not open $sample\_expected_taxon_mqc.html\n";
	print $HTML_OUT "<!--
id: 'expected_taxon'
section_name: 'Expected taxon'
-->
<p>The expected taxon <code>$expected</code> (<code>--expected_taxon</code>) was not found in the NCBI taxonomy (names.dmp). Check the spelling, or give its NCBI taxid instead.</p>
";
	close $HTML_OUT;
	open(my $COUNTS_OUT, ">", "$sample\_expected_taxon_counts.txt")   or die "Could not open $sample\_expected_taxon_counts.txt\n";
	print $COUNTS_OUT "NA\tNA\n";
	close $COUNTS_OUT;
	exit 0;
}

#Sort each top hit into the expected taxon, or a domain / phylum outside it
my $within=0;
my $outside=0;
my %outside_label;
open(my $OUTSIDE_OUT, ">", "$sample\_outside_expected_taxon.tsv")   or die "Could not open $sample\_outside_expected_taxon.tsv\n";
print $OUTSIDE_OUT "qseqid\tsseqid\tstitle\tpident\tevalue\tphylum\tqcovhsp\tstaxids\toutside_expected_taxon\n";
while (my $line=<$TOP_IN>){
	chomp $line;
	my @sp1= split("\t", $line);
	my @sp2= split("\;", $sp1[-1]);
	my $id= $sp2[0];

	my $in_expected=0;
	my ($domain, $phylum);
	my $steps=0;
	while (defined $id && exists $node_hash_parent{$id} && $steps < 100){
		$in_expected=1 if ($expected_ids{$id});
		my $rank= $node_hash_order{$id};
		$phylum= $name_hash{$id} if ($rank eq "phylum");
		$domain= $name_hash{$id} if ($rank eq "domain" || $rank eq "superkingdom" || $rank eq "acellular root");
		last if ($id eq "1");
		$id= $node_hash_parent{$id};
		$steps++;
	}

	if ($in_expected){
		$within++;
	}
	else{
		$outside++;
		my $label= defined $domain ? $domain : "Unknown taxon";
		$label .= " / $phylum" if (defined $phylum);
		$outside_label{$label}++;
		print $OUTSIDE_OUT "$line\t$label\n";
	}
}
close $OUTSIDE_OUT;

open(my $COUNTS_OUT, ">", "$sample\_expected_taxon_counts.txt")   or die "Could not open $sample\_expected_taxon_counts.txt\n";
print $COUNTS_OUT "$within\t$outside\n";
close $COUNTS_OUT;

#Bar chart: within the expected taxon, then the 10 most common groups outside it
my @labels= sort { $outside_label{$b} <=> $outside_label{$a} || $a cmp $b } keys %outside_label;
my @shown= @labels > 10 ? @labels[0..9] : @labels;
my $other= 0;
$other += $outside_label{$_} foreach (@labels > 10 ? @labels[10..$#labels] : ());
open(my $PLOT_OUT, ">", "$sample\_expected_taxon_mqc.tsv")   or die "Could not open $sample\_expected_taxon_mqc.tsv\n";
print $PLOT_OUT "# id: 'expected_taxon'
# section_name: 'Expected taxon'
# description: 'Whether the top hit of each sequence is within the expected taxon, $display, or outside it (grouped by domain / phylum). Hits outside can be contamination, or genes whose closest relatives in the database are outside the expected taxon. The top hits outside are listed in Taxo_summary/*_outside_expected_taxon.tsv.'
# plot_type: 'bargraph'
# pconfig:
#     id: 'expected_taxon_plot'
#     title: 'Top hits within and outside the expected taxon'
#     ylab: 'Sequences'
#     cpswitch_counts_label: 'Sequences'
Sample\tWithin expected taxon".join("", map { "\tOutside: $_" } @shown).($other ? "\tOutside: other" : "")."\n";
print $PLOT_OUT "$sample\t$within".join("", map { "\t$outside_label{$_}" } @shown).($other ? "\t$other" : "")."\n";
close $PLOT_OUT;
