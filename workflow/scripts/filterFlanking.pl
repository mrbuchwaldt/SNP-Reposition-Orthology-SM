#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use IPC::Open2;

main();

sub main{

	my ($inSNP,$fasta) = @ARGV;
	my @options = (
		'i|in=s',	\$inSNP,
		'f|fasta=s',	\$fasta
	);
	&GetOptions(@options);

	open(SNP, "<", $inSNP) or die "Cannot open SNP file: $inSNP\n";
	my %snps = ();
	my $matched = 0;
	my $unmatched = 0;

	while( <SNP> ){
		chomp($_);
		my ($snpid, $snpAlt, $chr, $pos, @rest) = split(",", $_);
		next if( $snpid eq "" || $snpAlt eq "" );
		#print STDERR Dumper($snpid, $snpAlt, $chr, $pos, @rest);

		if( ! exists $snps{$snpid} ){
			$snps{$snpid} = $_;
		} else {
			print STDERR "SNP: $snpid already exists in hash\n";
		}
        #if( ! exists $snps{$snpAlt} ){
        #	$snps{$snpAlt} = $_;
        #} else {
        #	print STDERR "SNP: $snpAlt already exists in hash\n";
        #}
	}
	close(SNP);

    #print STDERR Dumper(%snps);

	open(FASTA, "<", $fasta) or die "Cannot open fasta file: $fasta\n";

	my $header = "";
	my $seq = "";
    my $snpid = "";
	while( <FASTA> ){
		chomp($_);
		if( $_ =~ /^>.*/ ){
			if( $header eq "" ){
				$header = $_;
			    ( $snpid = $header ) =~ s/^>(B.*-p\d+)-?.*$/$1/;
                next;
			}
            #print STDERR Dumper($snpid);
			if( exists $snps{$snpid} ){
				print STDOUT $header . "\n" . $seq . "\n";
				$matched++;
			} else {
                print STDERR "SNP: $snpid did not match\n";
				$unmatched++;
			}

			$header = $_;
			$seq = "";
			( $snpid = $header ) =~ s/^>(B.*-p\d+)-?.*$/$1/;
		} else {
			$seq .= $_;
		}
	}

	#Do the last sequence too
	#( my $snpid = $_ ) =~ s/>(B.*-.*-p\d+)-?.*$/$1/;
	if( exists $snps{$snpid} ){
		print STDOUT $snpid . "\n" . $seq . "\n";
		$matched++;
	} else {
		$unmatched++;
	}

	close(FASTA);
	print STDERR "Matched: $matched\nUnmatched: $unmatched\n";
}
