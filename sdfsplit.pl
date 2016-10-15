#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

use lib dirname($0);
use QFileman;
use QChemConst;

my $doTot = 0;

GetOptions( 'tot|b'  => \$doTot );

die "Usage: ".basename($0)." [ -tot ] < qcout > [ num ] \n" unless scalar @ARGV >= 1;

my $fname = shift @ARGV;
my $data = QFileman::read($fname);

my @sdf_blks = $data =~ m/
    (.*?)           # coordinate block
    (?:\n|\r\n?)    # looking forward to newline character
    ^\$\$\$\$\n
/smxg;
die "No MDL MOL format found\n" if scalar @sdf_blks == 0;
#print foreach @sdf_blks;
#print scalar @sdf_blks;
#print scalar $sdf_blks[1];

my $i = 0; my $dir;
my $title;
my @lines;
### dump qchem output
foreach my $sdf (@sdf_blks) {

  @lines = $sdf =~ m/^(.*?)\n/;
  $title = $lines[0];
  @lines = $sdf =~ m{
        ^(\s+?[-]?(?:\d?|\d+)[.]?\d+)
	 (\s+?[-]?(?:\d?|\d+)[.]?\d+)
	 (\s+?[-]?(?:\d?|\d+)[.]?\d+)
	 (\s+?[a-zA-Z]+?)\s+?\ \ 0.*?(?:\n|\r\n?)
  }smxg;
  ### DEBUG
# print "----------\n";
# print scalar @lines/4,"\n";
# print $title,"\n";
# for (my $j=0; $j<scalar @lines; $j=$j+4){
#	  print $lines[$j+3],$lines[$j],$lines[$j+1],$lines[$j+2],"\n";
# }


  $i = $i + 1;
  $dir = sprintf "%03d",$i;
  mkdir $dir;
  my $output  = "$dir.xyz";
  my $output2 = "$dir.qcxyz";
  open OUT, ">$dir/$output" or die "$dir/$output: $!\n";
  open OUT2, ">$dir/$output2" or die "$dir/$output2: $!\n";
  print OUT scalar @lines/4,"\n";
  print OUT $title,"\n";
  print OUT2 "\$comment\n  $title\n\$end\n\n\$molecule\n 0  1\n";
  for (my $j=0; $j<scalar @lines; $j=$j+4){
 	  print OUT  $lines[$j+3],$lines[$j],$lines[$j+1],$lines[$j+2],"\n";
 	  print OUT2 $lines[$j+3],$lines[$j],$lines[$j+1],$lines[$j+2],"\n";
  }
  print OUT2 "\$end\n";
  close OUT;
  close OUT2;
  
  #b3lyp_6311gp($dir);
  #b3lyp_6311gp_chex($dir);
  #wb97x_6311gp($dir);
  wpbegdd_6311gp($dir);
} 
### DEBUG
#print $data;

sub b3lyp_6311gp{
  my $dir = shift @_;
  my $qcinp  = "$dir"."_b3lyp_6311gp_ief_marcus.in";
  open QCINP, ">$dir/$qcinp" or die "$dir/$qcinp: $!\n";
  print QCINP "\$comment\n  $title\n\$end\n\n\$molecule\n READ $dir.qcxyz\n\$end\n\n";
  my $qcrem = << 'QCREM';
$rem
  JOBTYPE               SP
  EXCHANGE              B3LYP
  BASIS                 6-311G*

  CIS_N_ROOTS           12
  RPA                   2
  CIS_SINGLETS          1
  CIS_TRIPLETS          0

  CIS_DYNAMIC_MEM       TRUE
  CIS_RELAXED_DENSITY   TRUE
  USE_NEW_FUNCTIONAL    TRUE

  SOLVENT_METHOD        PCM
  PCM_PRINT             1
  NTO_PAIRS		4

  MEM_TOTAL		4000
  MEM_STATIC		400
$end

$pcm
 Theory                 IEFPCM
 ChargeSeparation       Marcus
 StateSpecific          Perturb
$end

$solvent
 Dielectric             78.3553
 OpticalDielectric      1.777849
$end
QCREM

 print QCINP $qcrem;
 close QCINP;
}

sub wb97x_6311gp{
  my $dir = shift @_;
  my $qcinp  = "$dir"."_wb97x_6311gp_ief_marcus.in";
  open QCINP, ">$dir/$qcinp" or die "$dir/$qcinp: $!\n";
  print QCINP "\$comment\n  $title\n\$end\n\n\$molecule\n READ $dir.qcxyz\n\$end\n\n";
  my $qcrem = << 'QCREM';
$rem
  JOBTYPE               SP
  EXCHANGE              omegaB97X
  BASIS                 6-311G*

  CIS_N_ROOTS           12
  RPA                   2
  CIS_SINGLETS          1
  CIS_TRIPLETS          0

  CIS_DYNAMIC_MEM       TRUE
  CIS_RELAXED_DENSITY   TRUE
  USE_NEW_FUNCTIONAL    TRUE

  SOLVENT_METHOD        PCM
  PCM_PRINT             1
  NTO_PAIRS		4

  MEM_TOTAL		4000
  MEM_STATIC		400
$end

$pcm
 Theory                 IEFPCM
 ChargeSeparation       Marcus
 StateSpecific          Perturb
$end

$solvent
 Dielectric             78.3553
 OpticalDielectric      1.777849
$end
QCREM

 print QCINP $qcrem;
 close QCINP;
}

sub b3lyp_6311gp_chex{
  my $dir = shift @_;
  my $qcinp  = "$dir"."_b3lyp_6311gp_ief_marcus_chex.in";
  open QCINP, ">$dir/$qcinp" or die "$dir/$qcinp: $!\n";
  print QCINP "\$comment\n  $title\n\$end\n\n\$molecule\n READ $dir.qcxyz\n\$end\n\n";
  my $qcrem = << 'QCREM';
$rem
  JOBTYPE               SP
  EXCHANGE              B3LYP
  BASIS                 6-311G*

  CIS_N_ROOTS           12
  RPA                   2
  CIS_SINGLETS          1
  CIS_TRIPLETS          0

  CIS_DYNAMIC_MEM       TRUE
  CIS_RELAXED_DENSITY   TRUE
  USE_NEW_FUNCTIONAL    TRUE

  SOLVENT_METHOD        PCM
  PCM_PRINT             1
  NTO_PAIRS		4

  MEM_TOTAL		4000
  MEM_STATIC		400
$end

$pcm
 Theory                 IEFPCM
 ChargeSeparation       Marcus
 StateSpecific          Perturb
$end

$solvent
 Dielectric             2.016500	! Cyclohexane
 OpticalDielectric      2.035188
$end
QCREM

 print QCINP $qcrem;
 close QCINP;
}


sub wpbegdd_6311gp{
  my $dir = shift @_;
  my $qcinp  = "$dir"."_wpbegdd_6311gp_ief_marcus.in";
  open QCINP, ">$dir/$qcinp" or die "$dir/$qcinp: $!\n";
  print QCINP "\$comment\n  $title\n\$end\n\n\$molecule\n READ $dir.qcxyz\n\$end\n\n";
  my $qcrem = << 'QCREM';
$rem
  JOBTYPE               SP
  EXCHANGE              LRC-wPBEPBE
  BASIS                 6-311G*
  OMEGA                 300
  DFTVDW_JOBNUMBER      12
  DFTVDW_D2XMETHOD      3

  CIS_N_ROOTS           12
  RPA                   2
  CIS_SINGLETS          1
  CIS_TRIPLETS          0

  CIS_DYNAMIC_MEM       TRUE
  CIS_RELAXED_DENSITY   TRUE
  USE_NEW_FUNCTIONAL    TRUE

  SOLVENT_METHOD        PCM
  PCM_PRINT             1
  NTO_PAIRS		4

  MEM_TOTAL		4000
  MEM_STATIC		400
$end

$pcm
 Theory                 IEFPCM
 ChargeSeparation       Marcus
 StateSpecific          Perturb
$end

$solvent
 Dielectric             78.3553
 OpticalDielectric      1.777849
$end
QCREM

 print QCINP $qcrem;
 close QCINP;
}
