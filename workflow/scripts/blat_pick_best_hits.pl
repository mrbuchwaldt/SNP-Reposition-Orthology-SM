#!/usr/bin/perl

#THIS SCRIPT REQUIRES SORTED INPUT:
#Usage: sort -k10,10 -k1,1gr output.psl | blat_pick_best_hits.pl > filteredOutput.psl

#If you just want the best hits by most matching bases, JUST USE:
#sort -k10,10 -k1,1gr output.psl | sort -u -k10,10 --merge > bestHitsMostMatches.psl
#sort -k10,10 -k1,1gr B_snps_to_Bnigra_ref.psl | sort -u -k10,10 --merge > Bnigra_blat_BestHitsMostMatches.psl

#If you want all the tied best hits (if there are multiple alignments with equal most matches) use this script.

use strict;
use warnings;

my $currSNP = "";
my $currScore = 0;

while( <> ){
  chomp($_);

  my (@fields) = split("\t", $_);

  if( $fields[9] eq $currSNP ){
    next if( $fields[0] < $currScore);
    if( $fields[0] >= $currScore * 0.95 ){
      print STDOUT $_ . "\n";
    }
  } else {
    print STDOUT $_ . "\n";
    $currSNP = $fields[9];
    $currScore = $fields[0]
  }
}
