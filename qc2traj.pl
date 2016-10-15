#!/usr/bin/perl

### use 'beads' concept for step-jump

use strict;
use warnings;

### get standard path: perl -le 'print foreach @INC'

use lib "$ENV{HOME}/bin";	# add ~/bin
no lib ".";                     # remove cwd
use myConst;

# initialize variables
my @x = ();
my @y = ();
my @z = ();
my @vx = ();
my @vy = ();
my @vz = ();
my @a = ();
my @lines = ();
my ($atoms,$steps,$fsize,$data) = (0,0,0,0);

my $geomfile = "GEOMETRY.xyz";
my $cartsfile = "NucCarts";
my $velocfile = "NucVeloc";

die "Usage: qc2traj.pl <GEOMETRY.xyz> <NucCarts> <NucVeloc> \n" unless scalar @ARGV  == 3;
($geomfile,$cartsfile,$velocfile) = @ARGV;

## read in the reference geometry
$fsize = -s "$geomfile";
open TMP, $geomfile or die "Unable to open $geomfile !!\n";
read TMP, $data, $fsize;
close TMP;

#    \s?[a-zA-Z]+?\s+\.*?\s+.*?\s+.*?(?:\n|\r\n?) 
@lines = $data =~ m{
     \s?[a-zA-Z]+?\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+(?:\n|\r\n?)
}smxg;
# DEBUG
#print @lines;

$atoms = scalar @lines;

foreach (my $i=0; $i<$atoms; ++$i) {
   $lines[$i] =~ s/^\s*//g;
   my @line = split /\s+/, $lines[$i];
   $a[$i] = $line[0];
   $x[$i] = $line[1];
   $y[$i] = $line[2];
   $z[$i] = $line[3];
}

## read in the nuclear cartesian coordinates 
$fsize = -s "$cartsfile";
open TMP, $cartsfile || die "Unable to open $cartsfile !!\n";
read TMP, $data, $fsize;
close TMP;
@lines = $data =~ m{
 	[-]?(?:\d?|\d+)[.]?\d+.*?
	(?:\n|\r\n?)
}smxg;
# DEBUG
#print @lines;
$steps = scalar @lines;

foreach (my $j=0; $j<$steps; ++$j) {
   $lines[$j] =~ s/^\s*//g;
   my @line = split /\s+/, $lines[$j];
   die "Data counting not match the number of atoms\n" if scalar @line != $atoms*3 + 1;
   foreach (my $i=0; $i<$atoms; ++$i) {	## the first data given time
      $x[$atoms*$j + $i] = $line[$i*3+1];
      $y[$atoms*$j + $i] = $line[$i*3+2];
      $z[$atoms*$j + $i] = $line[$i*3+3];
   }
}

## read in the nuclear velocities
$fsize = -s "$velocfile";
open TMP, $velocfile || die "Unable to open $velocfile !!\n";
read TMP, $data, $fsize;
close TMP;
@lines = $data =~ m{
 	[-]?(?:\d?|\d+)[.]?\d+.*?
	(?:\n|\r\n?)
}smxg;
# DEBUG
#print @lines;
$steps = scalar @lines;

foreach (my $j=0; $j<$steps; ++$j) {
   $lines[$j] =~ s/^\s*//g;
   my @line = split /\s+/, $lines[$j];
   die "data count mismatch. exiting\n" if scalar @line != $atoms*3 + 1;
   foreach (my $i=0; $i<$atoms; ++$i) {	## the first data given time
      $vx[$atoms*$j + $i] = $line[$i*3+1] * myConst->BOHRS_TO_ANGSTROMS / myConst->AU_TIME_IN_SEC / 1.0e15;
      $vy[$atoms*$j + $i] = $line[$i*3+2] * myConst->BOHRS_TO_ANGSTROMS / myConst->AU_TIME_IN_SEC / 1.0e15;
      $vz[$atoms*$j + $i] = $line[$i*3+3] * myConst->BOHRS_TO_ANGSTROMS / myConst->AU_TIME_IN_SEC / 1.0e15;
   }
}

my $out = \*STDOUT;
my $allatms = $atoms * $steps;

print $out $atoms, "\nconverted from Q-CHEM BOMD NucCarts and NucVeloc\n";

## conver the units and form the trajectory file 
foreach (my $i=0; $i<$allatms; ++$i) {
   printf $out "%-3s %12.6f %12.6f %12.6f    %18.12g %18.12g %18.12g\n",
   $a[$i%$atoms], $x[$i], $y[$i], $z[$i], $vx[$i], $vy[$i], $vz[$i];
}	
