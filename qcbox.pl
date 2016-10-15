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
use List::Util qw[min max];

die "Usage: ".basename($0)." <file> [bound_in_A (default: 3)] [ 0.0 .. 0.1 .. 1.1 ] \n" unless @ARGV > 0;


my ($fname,$vdwR,$resol) = @ARGV;
# refer to van der Waals radius
$vdwR = 3.0 if ! defined $vdwR;

$resol= 0.5 if ! defined $resol;

my $mol = Molecule->new('xyzfile' => $fname);
#my ($Cx,$Cy,$Cz) = $mol->get_geom_center();
my @cen = $mol->get_geom_center();

# DEBUG
#printf "Geom center: %13.8f %13.8f %13.8f\n", $cen[0],$cen[1],$cen[2];
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
# determine box size
my $boxR = 0; my $diff = 0;
for my $i (0 .. 2) {
    $diff = $maxR[$i]+3.0 - ($cen[$i]+$vdwR);
    if ( $diff > 0 ) {
#       print $i," ", $diff,"\n";
       $boxR = max($boxR,abs($diff));
    }
    $diff = $minR[$i]-3.0 - ($cen[$i]-$vdwR);
    if ( $diff < 0 ) {
#       print $i," ", $diff,"\n";
       $boxR = max($boxR,abs($diff));
    }
}
die "Your box size must be larger than ", sprintf "%.1f", $boxR+$vdwR, "\n" if $boxR > 0;
$boxR = $boxR+$vdwR;


# round up to 0.1
for my $i (0 .. 2) {

    $maxR[$i] =  sprintf "%.1f", $cen[$i]+$boxR;
    $minR[$i] =  sprintf "%.1f", $cen[$i]-$boxR;
    #print $minR[$i], " ", $maxR[$i], "\n";
}

# get grid and range
my @mesh = (0,0,0);
my @resd2 = (0,0,0);
my @resd = (0,0,0);
my $resd = 0; my $resd2 = 0; my $length = 0; my $dist10 = 0;
for my $i (0 .. 2) {
    $dist10 = sprintf "%.1f", ($maxR[$i]-$minR[$i])*10;
    #print "$dist10\n";
    $resd[$i] = int($dist10) % int($resol*10);
    $resd2[$i] = $resd[$i]%2;
    if ($resd2[$i] == 0) {
      $resd[$i] = $resd[$i] / 2;
      $resd2[$i] = $resd[$i];
    } else {
      $resd2[$i] = $resd[$i];
      $resd[$i]  = ($resd[$i]  + 1) / 2;
      $resd2[$i] = ($resd2[$i] - 1) / 2;
    }
    #print "\t$resd2[$i]\t$resd[$i]\n";
    $length = ($maxR[$i]*10-$resd[$i])-($minR[$i]*10+$resd2[$i]);
    $mesh[$i] = $length / ($resol*10) + 1;

    $resd[$i]  = $resd[$i] / 10;
    $resd2[$i] = $resd2[$i] / 10;
}
# print out MO box
#print "Are you using the standard orientation ??\n\n";
print "\n";

my $ngrids  = $mesh[0]*$mesh[1]*$mesh[2];
print "\$plots\n";
printf "vdwR = %3.1f; den = %6.2f (/A); ngrids = %d\n",$vdwR,$resol,$ngrids;
for my $i (0 .. 2) {
    printf "%5d %12.6f %12.6f\n", $mesh[$i], $minR[$i]+$resd2[$i], $maxR[$i]-$resd[$i];
}
printf "%3d %3d %3d %3d\n",0,1,0,0;
printf "%3d\n",0;
print "\$end\n";


1;	# return true value
