#!/usr/bin/env perl

# ===================================
# Exciation analysis tool 
# ===================================

use strict;
use warnings;

use File::Basename;

use myConst;

die "Usage: ".basename($0)." < qcout > [ num ] \n" unless scalar @ARGV >= 1;

my $fname = shift @ARGV;
my $fsize = -s "$fname";

my $data;

open TMP, "<$fname" or die "$fname: $!\n";
read TMP, $data, $fsize;
close TMP;

my $num = 0;
$num = shift @ARGV if scalar @ARGV >=1;

die "This is garbage\n" if $num < 0;

my @diabatH = $data =~ m/
    showmatrix\ diabatH.*?=\s+?([-]?\d+?[.]?\d+?)
    (?:\n|\r\n?)    # looking forward to newline character
/smxg;

die "no BoysLoc or ER data found\n" if scalar @diabatH == 0;

### DEBUG
#print $_,"\n" foreach @diabatH;

my $lenH = scalar @diabatH;
#print $lenH,"\n";
my $dimH = sqrt($lenH);

my $isint = 0;
$isint = $dimH =~ /^\d+\z/;
die "\t\$dimH is not an positive integer\n" if ! $isint;

for (my $i=0; $i<6; $i++) {
    for (my $j=$i; $j<6; $j++) {
	printf "%10.6G\t",$diabatH[$i+$j*$dimH]*myConst->HARTREES_TO_EV;
    }
    print "\n";
}

print "\n";
for (my $i=0; $i<$dimH; $i++) {
    printf "%10.6G\n",$diabatH[$i+$i*$dimH]*myConst->HARTREES_TO_EV;
}




