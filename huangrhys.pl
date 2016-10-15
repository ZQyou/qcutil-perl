#!/usr/bin/env perl
# ****************************************************************************
#
# Q-Chem Perl Tools
#
# Calculate Huang--Rhys factor
#
# Input  : S0.xyz S1.xyz S0.norm_mwc
# Output : Huang--Rhys factor
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

my $doCART   = 0;
my @effRange = ();
my @vibPeak  = (); 
GetOptions(
    'cart|b'       => \$doCART,
    'eff|e=s{2,2}' => \@effRange,
    'vib|v=s{2,2}' => \@vibPeak
);

my $narg = scalar @ARGV;
die "Usage: ".basename($0)." [-cart] [-e min max] ref.xyz shifted.xyz vib_file_prefix \n" unless $narg >= 3;

### Load XYZ data
my $gxyz, my $exyz, my @normvec, my @normfreq, my @redmass;

my $gfile = shift @ARGV;
$gxyz = Molecule->new('xyzfile' => $gfile);

my $efile = shift @ARGV;
$exyz = Molecule->new('xyzfile' => $efile);

### Throw exceptions
# number of atoms dismatches AND order of atom type dismatches
my $is_same_molecule = 1;
if ( $gxyz->{totatm} != $exyz->{totatm} ) {
    $is_same_molecule = 0;
}
else {
    for (my $i=0; $i<$gxyz->{totatm}; $i++) { 
    	if ( $gxyz->{atm}[$i] ne $exyz->{atm}[$i] )  {
	    $is_same_molecule = 0;
	    last;
	}
    }
}
die "'$gfile' and '$efile' are not the same molecule\n" if ! $is_same_molecule;

### Load eigenvectors of mass-weighted Hessian matrix
my $vibpref = shift @ARGV;
my $fname = join ".", $vibpref, "norm_mwc";
$fname = join ".", $vibpref, "norm" if $doCART;
@normvec = QFileman::read($fname,'bin');
# DEBUG
#prtmat(@normvec);

### Load normal mode frequencies & reduced mass
$fname = join ".", $vibpref, "norm_freq";
@normfreq = QFileman::read($fname,'bin');

$fname = join ".", $vibpref, "norm_redmass";
@redmass = QFileman::read($fname,'bin');

# DEBUG
#prtmat(@redmass);


### Process XYZ data

my @gvec, my @evec, my @gmass;
for (my $i=0; $i<$gxyz->{totatm}; $i++) {
    my $atyp = $gxyz->{atm}[$i];
    my $atmass = $QChemConst::AMASS[$QChemConst::ELEMENTS{uc $atyp}];
    @gmass = (@gmass, $atmass, $atmass, $atmass);
    @gvec = (@gvec, $gxyz->{x}[$i], $gxyz->{y}[$i], $gxyz->{z}[$i]);
    @evec = (@evec, $exyz->{x}[$i], $exyz->{y}[$i], $exyz->{z}[$i]);
}
# DEBUG
#print scalar @gmass,"\n";

my $nmode = scalar @gvec;

=begin comment
### Load eigenvectors of mass-weighted Hessian matrix (excited states)
my $vibpref1 = shift @ARGV;
$fname = join ".", $vibpref1, "norm_mwc";
$fname = join ".", $vibpref1, "norm" if $doCART;
my @normvec1 = QFileman::read($fname,'bin');

### Calculate Duschinsky rotation
# D[3N-6,3N-6] = Tranpose(L_e[3N,3N-6])*L_g[3N,3N-6]
my @D = {};
my $D_elem, my $c, my $c1;
for ($c1=0; $c1<$nmode-6; $c1++) 
{
for ($c=0; $c<$nmode-6; $c++) 
{
   $D_elem = 0;

   for (my $r=0; $r<$nmode; $r++)
   {
       $D_elem += $normvec1[$c1*$nmode+$r]*$normvec[$c*$nmode+$r];
   }
   @D = (@D, $D_elem);
}}
prtmat(@D);
=end comment
=cut

### Calculate Huang--Rhys factor

# mass-weighted shift
my @dspl;
if ($doCART) 
{
    for (my $i=0; $i<$nmode; $i++) 
    {
    	@dspl = ( @dspl, ($evec[$i] - $gvec[$i]) );
    }
}
else 
{
    for (my $i=0; $i<$nmode; $i++) 
    {
    	@dspl = ( @dspl, sqrt($gmass[$i])*($evec[$i] - $gvec[$i]) );
    	#print sqrt($gmass[$i])*($evec[$i] - $gvec[$i]), "\n";
    }
}


# project @dspl to the ground-state norm mode coordinates
my @q;
for (my $j=0; $j<$nmode-6; $j++)	# use nonlinear molecule
{
    my $q_elem = 0;
    for (my $i=0; $i<$nmode; $i++)
    {
	$q_elem += $normvec[$j*$nmode+$i] * $dspl[$i];
    }
    @q = (@q, $q_elem);
}
# DEBUG
#printf "%12.6f\n",$_ foreach @q;

# unit conversion
use constant CFAC1 => 1e-10 * sqrt(QChemConst::ELECTRON_MASS_IN_KG / QChemConst::ELECTRON_MASS_IN_AMU);
use constant CFAC2 => 400 * (QChemConst::PI)**2 * QChemConst::SPEED_OF_LIGHT_IN_M_S / QChemConst::PLANCK_CONSTANT_IN_J_HZ;
my @w;
if ($doCART) 
{
    for (my $n=0; $n<$nmode-6; $n++)	# use nonlinear molecule
    {
#    	$s[$n] = $s[$n] * CFAC1 * sqrt( $normfreq[$n] * $redmass[$n] * CFAC2 );
    	$dspl[$n] = $q[$n] * CFAC1 * sqrt( $normfreq[$n] * $redmass[$n] * CFAC2 );
    }
}
else
{
    for (my $n=0; $n<$nmode-6; $n++)	# use nonlinear molecule
    {
#    	$s[$n] = $s[$n] * CFAC1 * sqrt( $normfreq[$n] * CFAC2 );
    	$dspl[$n] = $q[$n] * CFAC1 * sqrt( $normfreq[$n] * CFAC2 );
	$w[$n] = $normfreq[$n]*(QChemConst::PI)*2 * QChemConst::SPEED_OF_LIGHT_IN_M_S * 100;
    }
}

my @s;
for (my $n=0; $n<$nmode-6; $n++)	# use nonlinear molecule
{
    $s[$n] = 0.5 * $dspl[$n]**2;
}

### Effective Huang-Rhy factor and omega
my $effS = 0;
my $effF = 0;
if (scalar @effRange > 0)
{
   my $minF = shift @effRange;
   my $maxF = shift @effRange;
   my $effF1 = 0, my $effF2 = 0;
   my $curF = 0;
   for (my $n=0; $n<$nmode-6; $n++)	# use nonlinear molecule
   { 
      $curF = $normfreq[$n];
      if ($curF > $minF and $curF < $maxF) 
      {
         $effS  += $s[$n] * $curF;
	 $effF1 += $curF**4 * $dspl[$n]**2;
	 $effF2 += $curF**2 * $dspl[$n]**2;
      }
   }

   $effF = sqrt($effF1/$effF2);
   $effS = $effS/$effF;
   
   printf "# Effective mode (%-8.2f--%8.2f): S = %-9.6f, Freq = %-8.2f\n",$minF,$maxF,$effS,$effF;
}

#### Printout
if (scalar @vibPeak == 0) 
{
   printf "# Mode       S           Dspl.       dQ          Freq      Red. mass\n";
   if ($doCART) {
   printf "#                                 (Angstrom)    (cm^-1)      (amu)\n";
   } else {
   printf "#                                (A amu**0.5)   (cm^-1)      (amu)\n";
   }
   for (my $n=0; $n<$nmode-6; $n++)	# use nonlinear molecule
   {
       printf "%4d %12.6f %12.6f %12.6f    %8.2f %10.4f\n",$n+1,$s[$n],$dspl[$n],$q[$n]/0.529,$normfreq[$n],$redmass[$n];
       #printf "%4d %12.6f %12.6f %12.6f    %8.2f %10.4f %12.6f\n",$n+1,$s[$n],$dspl[$n],$q[$n],$normfreq[$n],$redmass[$n],$w[$n];
       #printf "%4d %12.6f %12.6f %12.6f    %8.2f %10.4f %12.6f\n",$n+1,$s[$n],$dspl[$n],$q[$n]/sqrt(QChemConst::ELECTRON_MASS_IN_AMU)/0.529,$normfreq[$n],$redmass[$n],$w[$n];
   }
} else {
   my $e0 = shift @vibPeak;
   my $f0 = shift @vibPeak;
   my $facS = 0;
   for (my $m=0; $m<20; $m++) {
      $facS = exp(-$effS) * $effS**$m / fac($m);
      printf "%3d %8.0f %12.6g %12.6g\n",$m, $e0+$effF*$m, $f0*$facS, $facS;
   }
}

### Formatted matrix print
sub prtmat
{
  my @mat = @_;
  my $row = sqrt(scalar @mat);
  my $count = 0;
  my $col = 6;
  foreach my $num (@mat)
  {
    $count++;
    print "\n" if $count > $col;
    $count = 1 if $count > $col;
    #printf " %14.7E",$num;
    printf " %12.6f",$num;
  }
  print "\n";
}


sub fac
{
   my $n = shift;
   my $val = 1;
   for (my $i=$n; $i>0; $i--) {
      $val *= $i;
   }
   return $val;

}
