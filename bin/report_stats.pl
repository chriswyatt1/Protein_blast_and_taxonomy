#!/usr/bin/env perl
#report_stats.pl
use strict;
use warnings;

#Writes the MultiQC report sections for one input file: a search summary, the identity and query
#coverage of the top hits, the taxonomy of the top hits (phylum and genus) and the pie chart figure.
die "Please specify (1) sample name (2) query fasta (3) top hits (tophitsonly.pl output, with ncbi_txids_taxonomy.all.pl rank tables next to it) (4) taxonomy figure (png) (5, optional) expected_taxon.pl counts\n" unless(@ARGV==4 || @ARGV==5);

my $sample = $ARGV[0];
my $query = $ARGV[1];
my $top = $ARGV[2];
my $figure = $ARGV[3];
my $expected_counts = $ARGV[4];

sub median {
	my @sorted= sort { $a <=> $b } @_;
	my $n= scalar(@sorted);
	return "NA" unless ($n);
	return sprintf("%.1f", $n % 2 ? $sorted[($n-1)/2] : ($sorted[$n/2-1]+$sorted[$n/2])/2);
}

#Count the query sequences (the fasta may be gzipped)
open(my $QUERY_IN, "-|", "gzip", "-cdf", $query)   or die "Could not open $query \n";
my $queries=0;
while (my $line=<$QUERY_IN>){
	$queries++ if ($line =~ m/^>/);
}
close $QUERY_IN;

#Percent identity and query coverage of each query's top hit
#(columns: qseqid sseqid stitle pident evalue phylum qcovhsp staxids)
open(my $TOP_IN, "<", $top)   or die "Could not open $top \n";
my @identity;
my @coverage;
my $full_length_high=0;
while (my $line=<$TOP_IN>){
	chomp $line;
	my @split= split("\t", $line);
	push (@identity, $split[3]);
	push (@coverage, $split[6]);
	$full_length_high++ if ($split[3] >= 95 && $split[6] >= 90);
}
close $TOP_IN;

my $hits= scalar(@identity);
my @bins= ("<30%", "30-50%", "50-70%", "70-90%", "90-95%", ">=95%");
my %bin_count= map { $_ => 0 } @bins;
foreach my $perc (@identity){
	my $bin= $perc >= 95 ? ">=95%" : $perc >= 90 ? "90-95%" : $perc >= 70 ? "70-90%" : $perc >= 50 ? "50-70%" : $perc >= 30 ? "30-50%" : "<30%";
	$bin_count{$bin}++;
}
my @cov_bins= ("<25%", "25-50%", "50-75%", "75-90%", ">=90%");
my %cov_bin_count= map { $_ => 0 } @cov_bins;
foreach my $perc (@coverage){
	my $bin= $perc >= 90 ? ">=90%" : $perc >= 75 ? "75-90%" : $perc >= 50 ? "50-75%" : $perc >= 25 ? "25-50%" : "<25%";
	$cov_bin_count{$bin}++;
}

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

#Top hits outside the expected taxon, from expected_taxon.pl (only with --expected_taxon)
my ($expected_header, $expected_values)= ("", "");
if (defined $expected_counts){
	open(my $EXPECTED_IN, "<", $expected_counts)   or die "Could not open $expected_counts \n";
	my $line=<$EXPECTED_IN>;
	close $EXPECTED_IN;
	chomp $line;
	my ($within, $outside)= split("\t", $line);
	my $outside_perc= ($within ne "NA" && $within+$outside) ? sprintf("%.1f", 100*$outside/($within+$outside)) : "NA";
	$expected_header= "\tTop hit outside expected taxon\t% outside expected taxon";
	$expected_values= "\t$outside\t$outside_perc";
}

#Search summary table
my $with_hit_perc= $queries ? sprintf("%.1f", 100*$hits/$queries) : "NA";
open(my $SUMMARY_OUT, ">", "$sample\_search_summary_mqc.tsv")   or die "Could not open $sample\_search_summary_mqc.tsv\n";
print $SUMMARY_OUT "# id: 'search_summary'
# section_name: 'Search summary'
# description: 'How many sequences in each input file found a hit, and how similar their top hits are. Identity >= 95% usually means the same or a very closely related species is in the database; with coverage >= 90% the match also spans most of the sequence.'
# plot_type: 'table'
# pconfig:
#     id: 'search_summary_table'
#     col1_header: 'Input'
Input\tSequences searched\tWith a hit\t% with a hit\tTop hit >= 95% identity\tTop hit >= 95% identity and >= 90% coverage\tMedian identity (%)\tMedian coverage (%)\tPhyla\tGenera\tSpecies$expected_header
$sample\t$queries\t$hits\t$with_hit_perc\t$bin_count{'>=95%'}\t$full_length_high\t".median(@identity)."\t".median(@coverage)."\t".scalar(@phyla)."\t".scalar(@genera)."\t".scalar(@species)."$expected_values\n";
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

#Query coverage of the top hits, including the sequences with no hit
open(my $COVERAGE_OUT, ">", "$sample\_coverage_mqc.tsv")   or die "Could not open $sample\_coverage_mqc.tsv\n";
print $COVERAGE_OUT "# id: 'top_hit_coverage'
# section_name: 'Coverage of top hits'
# description: 'How much of each sequence is covered by its top hit (query coverage of the alignment). Low coverage means only part of the sequence matched, such as one shared domain, so a high identity there says less.'
# plot_type: 'bargraph'
# pconfig:
#     id: 'top_hit_coverage_plot'
#     title: 'Coverage of top hits'
#     ylab: 'Sequences'
#     cpswitch_counts_label: 'Sequences'
Sample\tNo hit\t".join("\t", @cov_bins)."\n";
print $COVERAGE_OUT "$sample\t".($queries-$hits)."\t".join("\t", map { $cov_bin_count{$_} } @cov_bins)."\n";
close $COVERAGE_OUT;

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
