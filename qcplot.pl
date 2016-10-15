#!/usr/bin/env perl
# ****************************************************************************
#
# perl tools for Q-chem
#
# determine the boudary and density of cube file 
#
# ****************************************************************************

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

use lib dirname($0);
use QChemConst;
use QFileman;
use QParseLib;

# Grid point ditribution (definition in cubegen):
# course -  3 grid points/bohr (-2)
# medium -  6 grid points/bohr (-3)
#   fine - 12 grid points/bohr (-4)

die "Usage: ".basename($0)." <file> [bound_in_A (default: 3)] [den_lvl=1|2|3]\n" unless @ARGV > 0;


my ($fname,$vdwR,$denlvl) = @ARGV;
# refer to van der Waals radius
$vdwR = 3.0 if ! defined $vdwR;

$denlvl = 1 if ! defined $denlvl;
$denlvl = 1 if $denlvl > 3 || $denlvl < 1;

my $den  =  ( $denlvl <= 2 ) ? $denlvl*3/QChemConst::BOHRS_TO_ANGSTROMS : $denlvl*4/QChemConst::BOHRS_TO_ANGSTROMS; 

my $mol = Molecule->new('xyzfile' => $fname);

# DEBUG
#print $_,"\n" foreach @lines;
#exit 1;

my @maxR = (-1e10,-1e10,-1e10);
my @minR = (1e10,1e10,1e10);
for (my $n=0; $n<$mol->{totatm}; $n++) {

    my @curR = ($mol->{x}[$n],$mol->{y}[$n],$mol->{z}[$n]);
    for my $i (0 .. 2) {
	#print $curR[$i],"\n";
 	$maxR[$i] = $curR[$i] if $curR[$i] > $maxR[$i];
 	$minR[$i] = $curR[$i] if $curR[$i] < $minR[$i];
    }
}

my @mesh = (0,0,0);
# print out MO box
print "Are you using the standard orientation ??\n\n";
print "\$plots\n";
printf "vdwR = %3d and mesh = %6.2f (/A)\n",$vdwR,$den;
for my $i (0 .. 2) {
    $mesh[$i] = (($maxR[$i]+$vdwR)-($minR[$i]-$vdwR))*$den + 1;
    printf "%5d %12.6f %12.6f\n", $mesh[$i], $minR[$i]-$vdwR, $maxR[$i]+$vdwR;
}
printf "%3d %3d %3d %3d\n",0,0,0,0;
print "\$end\n";

1;	# return true value
