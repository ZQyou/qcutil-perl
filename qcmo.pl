#!/usr/bin/env perl
# ****************************************************************************
#
# perl tools for Q-chem
#
# Mulliken / Becke Population
#
# ZQY (08/07)
#
# ****************************************************************************

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

use lib dirname($0);
use QChemConst;
use QParse;
use QParseLib;

sub prtmos (\@@)
{
   my ($mos, @moeng) = @_;
   #print @$mos;
   foreach (@$mos) 
   {
      printf "%f  ", $moeng[$_-1]*QChemConst::HARTREES_TO_EV;
   }
   print "\n";
}

### variables for commandline parsing.
my @mos  = ();
my @homo = ();
my @lumo = ();
my $prtBeta = 0;
my $prtAll  = 0;
### parse commandline arguments
GetOptions( 
    'beta|b'       => \$prtBeta,
    'all|a'        => \$prtAll,
    'homo|h=s{,}'  => \@homo,
    'lumo|l=s{,}'  => \@lumo,
    'mo|m=s{,}'    => \@mos
); 
  
die "Usage: ".basename($0)." <file> <# of mo_sets>  [ -m mos ] [ -h homos ] [ -l lumos ] \n" unless scalar @ARGV > 0;

my ($qcout,$whichone) = @ARGV;

my $qparse = QParse->new($qcout);
my @moeng = $qparse->moeng();

my $num_moeng = scalar @moeng;
$whichone = 1 if $prtAll;

die "$num_moeng Orbital Energies section found \n" if ! defined $whichone or $whichone < 1 or $whichone > $num_moeng;

my @moslist = ($whichone);
@moslist = (1..$num_moeng) if $prtAll;

foreach (@moslist)
{

my $whichone = $_;

my $mo = MOEng->new($moeng[$whichone-1]);
my $noccA = $mo->{noccA}; my $nvirA = $mo->{nvirA};
my $noccB = $mo->{noccB}; my $nvirB = $mo->{nvirB};

my $doBeta = $prtBeta;
$doBeta = 0 if $noccB == 0 and $prtBeta;

if (scalar @mos)
{
   my @orbA = (@{$mo->{occA}},@{$mo->{virA}});
   prtmos(@mos,@orbA);
   if ($doBeta)
   {
      my @orbB = (@{$mo->{occB}},@{$mo->{virB}});
      prtmos(@mos,@orbB);
   }
}
elsif (scalar @homo)
{ 
   my @homoA = ();
   for (my $i=0; $i<scalar @homo; $i++) {
      $homoA[$i] = -$homo[$i] + $noccA + 1;
   }
   prtmos(@homoA,@{$mo->{occA}});
   if ($doBeta)
   {
      my @homoB = ();
      for (my $i=0; $i<scalar @homo; $i++) {
         $homoB[$i] = -$homo[$i] + $noccB + 1;
      }
      prtmos(@homoB,@{$mo->{occB}});
   }
}
elsif (scalar @lumo)
{ 
   prtmos(@lumo,@{$mo->{virA}});
   if ($doBeta)
   {
      prtmos(@lumo,@{$mo->{virB}});
   }
}
else
{
   printf "NOccA = %d, NVirA = %d\n",$noccA,$nvirA;
   printf "NOccB = %d, NVirB = %d\n",$noccB,$nvirB;
}

}
