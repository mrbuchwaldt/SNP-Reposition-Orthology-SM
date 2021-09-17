#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;

main();

sub main{

	#Produce a bedfile for comparing to the B. carinata genome from a subset of SNPs
	my ($snps, $snpNames, $newPosSNPs, $unplacedOut) = @ARGV;
	my @options = (
		's|snps=s',	\$snps,
		'p|new-pos=s',	\$newPosSNPs
	);
	&GetOptions(@options);

	#Intersect the snps with the genome gff (genes) 
	# bedtools window -w 250000 -a $snps -b $genome

	my %newPositions = ();
	open(POS, "<", $newPosSNPs) or die "cannot open SNP positions file\n";
	while( <POS> ){
		chomp($_);
		my ($chr, $start, $end, $snp) = split("\t", $_);
		$newPositions{$snp} = $_;
	}
	close(POS);

	my %snpNameConvert = ();
	open(NAME, "<", $snpNames) or die "Cannot open SNP names file: $snpNames\n";
	while( <NAME> ){
		chomp($_);
		my ($snpid, $snpalt, @rest) = split(",", $_);
		$snpNameConvert{$snpalt} = $snpid;
	}

	open(SNP, "<", $snps) or die "Cannot open SNPs file: $snps\n";
	open(UNPLACED, ">", $unplacedOut) or die "Cannot open SNPs file: $unplacedOut\n";
	<SNP>;
	while( <SNP> ){
		chomp($_);
		my ($trait, $snpalt, $chr, $pos) = split(",", $_);

		if( exists $newPositions{ $snpNameConvert{$snpalt} } ){
			print STDOUT $newPositions{ $snpNameConvert{$snpalt} } . "\n";
		} else {
			print UNPLACED $_ . "\n";
		}
	}
	close(SNP);
	close(UNPLACED);
}