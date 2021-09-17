#!/usr/bin/env perl

use strict;
use warnings;
use POSIX;
use Data::Dumper;

my ($bestHits, $snpFile, $outBed) = @ARGV;

open(HITS, "<", $bestHits) or die "Cannot open best hits file: $bestHits\n";

my %carPos = ();
my $noSNPAlign = 0;

while( <HITS> ){
	chomp($_);

	my @fields = split("\t", $_);

	#Reformat the SNP IDs
	( my $snpID = $fields[9] ) =~ s/(.*-p\d+).*/$1/;

	#Calculate position of the SNP
	my $newPos;

	#The position in the query that corresponds to the SNP
	my $SNPBase = ceil($fields[10]/2);

	my @blockSizes = split(",", $fields[18]);
	my @qblockStarts = split(",", $fields[19]);
	my @tblockStarts = split(",", $fields[20]);

	my $sumBases = $qblockStarts[0];

	for( my $i = 0; $i<scalar(@blockSizes); $i++){
		
		if($sumBases + $blockSizes[$i] > $SNPBase){
			$newPos = $tblockStarts[$i] + ($SNPBase - $sumBases);
		} else {
			$sumBases += $blockSizes[$i];
		}

		#Add tGaps between the blocks if they exists (query bases get used up)
		if( $i < scalar(@blockSizes)-1 ){
			$sumBases += $qblockStarts[$i+1] - $sumBases;
		}
	}
	if( ! length $newPos ){
		print STDERR "SNP position didn't align for $snpID\n";
		$noSNPAlign++;
		next;
	}
	if( ! exists $carPos{$snpID} ){
		$carPos{$snpID} = "$fields[13],$newPos";
	} else {
		$carPos{$snpID} .= ",$fields[13],$newPos";
	}
}


close(HITS);
open(SNP, "<", $snpFile) or die "Cannot open SNP file: $snpFile\n";
open(BED, ">", $outBed) or die "Cannot open output bed file: $outBed\n";

my $missCount = 0;

while( <SNP> ){
	chomp($_);

	my ($snpName, $snpID, $chr, $pos, @rest) = split(",", $_);

	if( exists $carPos{$snpName} ){
		print STDOUT $_ . "," . $carPos{$snpName} . "\n";
		my @BcarPos = split(",", $carPos{$snpName});
		for( my $i = 0; $i<scalar(@BcarPos);$i+=2 ){
			print BED join("\t", $BcarPos[$i],$BcarPos[$i+1],$BcarPos[$i+1]+1,$snpName) . "\n";
		}
		delete $carPos{$snpName};
	} else {
		print STDERR "$snpName had no alignment to the B. carinata genome.\n";
		print STDOUT $_ . "\n";
		$missCount++;
	}
}
print STDERR Dumper(%carPos);
print STDERR "$missCount SNPs had no B. car alignments\n";
print STDERR "$noSNPAlign sequences did not align over the SNP position\n"

