#!/usr/bin/perl
#plot_event.pl
use strict;
use warnings;

die "Please specify (1) Blast results\n" unless(@ARGV==1);


my $input = $ARGV[0];

my $OUT_file="Horizontal_assesment.tsv";

#initiaite groups from conversion file.
open(my $INPUT_IN, "<", $input)   or die "Could not open $input \n";
open(my $outhandle, ">", $OUT_file)   or die "Could not open $OUT_file\n";

my %genes;

while (my $line=<$INPUT_IN>){
	chomp $line;
	my @split= split("\t", $line);

	my $id= $split[0];
	my $kingdom= $split[5];
	my $perc= $split[3];

	if ($genes{$id}{$kingdom}){
		my $old=$genes{$id}{$kingdom};
		my @sp=split("\t", $old);
		my $tot=$sp[0]+$perc;
		my $num=$sp[1]+1;
		$genes{$id}{$kingdom}="$tot\t$num";
	}
	else{
		$genes{$id}{$kingdom}="$perc\t1";
	}

}

foreach my $key (keys %genes) {
	print $outhandle "$key";
	foreach my $king (keys %{$genes{$key}}) {
		my @value= split("\t", $genes{$key}{$king});
		my $average_perc=$value[0]/$value[1];
		my $round_perc=sprintf("%.2f", $average_perc);
		print $outhandle "\t$king ($round_perc of $value[1])";
	}
	print $outhandle "\n";
}


=cut

foreach my $outter (keys %hash) {
  foreach my $inner (keys %{$hash{$outter}}) {
    print "$outter - $inner = ", $hash{$outter}{$inner}, "\n";
  }
}
