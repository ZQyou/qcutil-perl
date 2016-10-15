#!/usr/bin/env perl
# ****************************************************************************
#
# perl tools for Q-Chem
#
# ****************************************************************************

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

#use lib $ENV{"HOME"}."/qcutil";		# add ~/qcutil
use lib dirname($0);
use QChemConst;
use QFileman;
use QParseLib;

my $vdwR = 3.0;
my @qmAtm;
my $strPrt = "qmnum";
GetOptions( 
    'qm=i{2}'    	=> \@qmAtm,
    'print|p=s{0,1}'	=> \$strPrt,
    'radius|r=f'	=> \$vdwR
);

my $narg = scalar @ARGV;
die "Usage: ".basename($0)." [ -r vdwR ] [ -p <qm> ] -qm <FirstQMAtm> <LastQMAtm> <file>
  Default: vdwR = 3 Angstrom ; print option is qmnum (qm atom numbers)\n"
if $narg != 1 or scalar @qmAtm < 2 ;

my $data;
if ($narg == 1)
{
   my $fname = shift @ARGV;
   $data = QFileman::read($fname);
}

### Get XYZ
my $mol = Molecule->new('gmxXYZ' => $data);

my @qmList = @{$mol->{num}}[$qmAtm[0]-1..$qmAtm[1]-1];
my $dist  = 0;
my $inBox = 0;
my $mcenx; my $mceny; my $mcenz;
my $mass  = 0; my $totmass = 0;
my $qmx; my $qmy; my $qmz;

for (my $j=$qmAtm[1]; $j<$mol->{totatm}; $j=$j+3)
{
   $inBox = 0;

   for (my $i=$qmAtm[0]-1; $i<$qmAtm[1]; $i++)
   {  
       $qmx = $mol->{x}[$i];
       $qmy = $mol->{y}[$i];
       $qmz = $mol->{z}[$i];

       $mcenx = 0; $mceny = 0; $mcenz = 0; $totmass = 0;
       for (my $k=0; $k<3; $k++) 
       {
	   $mass = $QChemConst::AMASS[$QChemConst::ELEMENTS{$mol->{atm}[$j+$k]}];
	   $mcenx += $mol->{x}[$j+$k]*$mass;
	   $mceny += $mol->{y}[$j+$k]*$mass;
	   $mcenz += $mol->{z}[$j+$k]*$mass;
	   $totmass += $mass;
       }

       $dist = sqrt( ($mcenx/$totmass - $qmx)**2 +
                     ($mceny/$totmass - $qmy)**2 +
                     ($mcenz/$totmass - $qmz)**2 );

       if ($dist < $vdwR)
       {
           $inBox = 1;
	   push @qmList, @{$mol->{num}}[$j..$j+2];
       }
       last if $inBox;
   }
}

if ($strPrt eq "qmnum")
{
   print_qc_qm_atoms(@qmList);
}
elsif ($strPrt eq "qm")
{
   print "\$molecule\n";
   print " 0  1\n";
   $mol->print('gmx'=>1, @qmList);
   print "\$end\n";
}
elsif ($strPrt eq "mm")
{
   print "\$molecule\n";
   print " 0  1\n";
   $mol->print('gmx'=>2, @qmList);
   print "\$end\n";
}
elsif ($strPrt eq "qmmm")
{
   print "\$molecule\n";
   print " 0  1\n";
   $mol->print('gmx'=>2);
   print "\$end\n\n";
   print_qc_qm_atoms(@qmList);
}

sub print_qc_qm_atoms {
   my @qmList = @_;
   print "\$qm_atoms\n";
   ### print solute
   my $batchNum = 10;
   my $qmAtmTot = $qmAtm[1] - $qmAtm[0] + 1;
   my $lastNum  = $qmAtmTot % $batchNum;
   my $prtBatch = ($qmAtmTot - $lastNum) / $batchNum;
   for (my $i=0 ; $i<$prtBatch; $i++) {
      print $_," " foreach (splice @qmList, 0, $batchNum);
      print "\n";
   }
   if ($lastNum > 0) {
      print $_," " foreach (splice @qmList, 0, $lastNum);
      print "\n";
   }
   ### print water
   while (@qmList) {
     print $_, " " foreach (splice @qmList, 0, 3);	   
     print "\n";
   }
   print "\$end\n";
}
