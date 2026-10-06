#!/usr/bin/env perl
#report_stats.pl
use strict;
use warnings;

#Writes the MultiQC report sections for one input file: a search summary, the identity of the
#top hits, the taxonomy of the top hits (phylum and genus) and the pie chart figure.
die "Please specify (1) sample name (2) query fasta (3) top hits (tophitsonly.pl output, with ncbi_txids_taxonomy.all.pl rank tables next to it) (4) taxonomy figure (png)\n" unless(@ARGV==4);

my $sample = $ARGV[0];
my $query = $ARGV[1];
my $top = $ARGV[2];
my $figure = $ARGV[3];

#Count the query sequences (the fasta may be gzipped)
open(my $QUERY_IN, "-|", "gzip", "-cdf", $query)   or die "Could not open $query \n";
my $queries=0;
while (my $line=<$QUERY_IN>){
	$queries++ if ($line =~ m/^>/);
}
close $QUERY_IN;

#Percent identity of each query's top hit
open(my $TOP_IN, "<", $top)   or die "Could not open $top \n";
my @identity;
while (my $line=<$TOP_IN>){
	chomp $line;
	my @split= split("\t", $line);
	push (@identity, $split[3]);
}
close $TOP_IN;

my $hits= scalar(@identity);
my @bins= ("<30%", "30-50%", "50-70%", "70-90%", "90-95%", ">=95%");
my %bin_count= map { $_ => 0 } @bins;
foreach my $perc (@identity){
	my $bin= $perc >= 95 ? ">=95%" : $perc >= 90 ? "90-95%" : $perc >= 70 ? "70-90%" : $perc >= 50 ? "50-70%" : $perc >= 30 ? "30-50%" : "<30%";
	$bin_count{$bin}++;
}
my @sorted= sort { $a <=> $b } @identity;
my $median= !$hits ? "NA" : sprintf("%.1f", $hits % 2 ? $sorted[($hits-1)/2] : ($sorted[$hits/2-1]+$sorted[$hits/2])/2);

#Taxa of the top hits, from the rank tables written by ncbi_txids_taxonomy.all.pl
sub read_rank {
	my ($rank)= @_;
	my @taxa;
	open(my $RANK_IN, "<", "$top\_$rank")   or die "Could not open $top\_$rank \n";
	my $header=<$RANK_IN>;
	while (my $line=<$RANK_IN>){
		chomp $line;
		my @split= split("\t", $line);
		next unless (@split == 2 && $split[0] ne "");
		push (@taxa, [$split[0], $split[1]]);
	}
	close $RANK_IN;
	return @taxa;
}
my @phyla= read_rank("phylum");
my @genera= read_rank("genus");
my @species= read_rank("species");

#Search summary table
my $with_hit_perc= $queries ? sprintf("%.1f", 100*$hits/$queries) : "NA";
my $high_perc= $hits ? sprintf("%.1f", 100*$bin_count{">=95%"}/$hits) : "NA";
open(my $SUMMARY_OUT, ">", "$sample\_search_summary_mqc.tsv")   or die "Could not open $sample\_search_summary_mqc.tsv\n";
print $SUMMARY_OUT "# id: 'search_summary'
# section_name: 'Search summary'
# description: 'How many sequences in each input file found a hit, and how similar their top hits are. Identity >= 95% usually means the same or a very closely related species is in the database.'
# plot_type: 'table'
# pconfig:
#     id: 'search_summary_table'
#     col1_header: 'Input'
Input\tSequences searched\tWith a hit\t% with a hit\tTop hit >= 95% identity\t% of hits >= 95% identity\tMedian identity (%)\tPhyla\tGenera\tSpecies
$sample\t$queries\t$hits\t$with_hit_perc\t$bin_count{'>=95%'}\t$high_perc\t$median\t".scalar(@phyla)."\t".scalar(@genera)."\t".scalar(@species)."\n";
close $SUMMARY_OUT;

#Identity of the top hits, including the sequences with no hit
open(my $IDENTITY_OUT, ">", "$sample\_identity_mqc.tsv")   or die "Could not open $sample\_identity_mqc.tsv\n";
print $IDENTITY_OUT "# id: 'top_hit_identity'
# section_name: 'Identity of top hits'
# description: 'Percent identity of the top hit of every sequence searched. Identity >= 95% usually means the same or a very closely related species is in the database.'
# plot_type: 'bargraph'
# pconfig:
#     id: 'top_hit_identity_plot'
#     title: 'Identity of top hits'
#     ylab: 'Sequences'
#     cpswitch_counts_label: 'Sequences'
Sample\tNo hit\t".join("\t", @bins)."\n";
print $IDENTITY_OUT "$sample\t".($queries-$hits)."\t".join("\t", map { $bin_count{$_} } @bins)."\n";
close $IDENTITY_OUT;

#Taxonomy bar charts: the 10 most common taxa, and the rest as Other
sub write_taxa {
	my ($rank, $label, @taxa)= @_;
	my @shown= @taxa > 10 ? @taxa[0..9] : @taxa;
	my $other= 0;
	$other += $_->[1] foreach (@taxa > 10 ? @taxa[10..$#taxa] : ());
	open(my $TAXA_OUT, ">", "$sample\_$rank\_mqc.tsv")   or die "Could not open $sample\_$rank\_mqc.tsv\n";
	print $TAXA_OUT "# id: 'top_hit_$rank'
# section_name: 'Top hit $label'
# description: 'The $label of each sequence top hit (the 10 most common in each input file, the rest grouped as Other).'
# plot_type: 'bargraph'
# pconfig:
#     id: 'top_hit_$rank\_plot'
#     title: 'Top hit $label'
#     ylab: 'Sequences'
#     cpswitch_counts_label: 'Sequences'
Sample\t".join("\t", map { $_->[0] } @shown).($other ? "\tOther" : "")."\n";
	print $TAXA_OUT "$sample\t".join("\t", map { $_->[1] } @shown).($other ? "\t$other" : "")."\n";
	close $TAXA_OUT;
}
write_taxa("phylum", "phylum", @phyla);
write_taxa("genus", "genus", @genera);

#The pie chart figure, embedded in the report (base64 from coreutils, as MIME::Base64 is not in every perl)
open(my $FIGURE_IN, "-|", "base64", "-w0", $figure)   or die "Could not open $figure \n";
my $png_base64= <$FIGURE_IN>;
close $FIGURE_IN;
(my $section_id= "taxonomy_figure_$sample") =~ s/[^A-Za-z0-9_]/_/g;
open(my $FIGURE_OUT, ">", "$sample\_taxonomy_figure_mqc.html")   or die "Could not open $sample\_taxonomy_figure_mqc.html\n";
print $FIGURE_OUT "<!--
id: '$section_id'
section_name: 'Taxonomy figure: $sample'
description: 'The taxonomy of the top hits at each rank, from kingdom to subspecies (also in Taxo_figure/ as a PDF). Taxa with less than 1% of the hits are not labelled.'
-->
<img src=\"data:image/png;base64,".$png_base64."\" style=\"max-width:100%\">
";
close $FIGURE_OUT;
