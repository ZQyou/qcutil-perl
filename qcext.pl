#!/usr/bin/env perl

# ===================================
# Exciation analysis tool 
# ===================================

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

use lib dirname($0);
use QFileman;
use QChemConst;

my $doTot = 0;
my $getSS = 0;

GetOptions( 'tot|b'  => \$doTot,
	    'ptss|b' => \$getSS
          );

die "Usage: ".basename($0)." [ -tot ] [ -ptss ] < qcout > [ num ] \n" unless scalar @ARGV >= 1;

my $fname = shift @ARGV;
my $data = QFileman::read($fname);

my @states = ();
my $state_arg = shift @ARGV if scalar @ARGV >=1;
if ($state_arg)
{
   foreach my $item (split /,/,$state_arg)
   {
       my @toks = split /-/,$item; 
       my $head = shift @toks;
       my $tail = $head;
       $tail = shift @toks if scalar @toks;
       for (my $i=$head; $i<=$tail; $i++)
       {
  	   #print "$i ";
	   push @states,$i;
       }
   }
}
#die "This is garbage\n" if $num < 0;

#((?:TDDFT|TDDFT\/TDA)\ Excitation\ Energies.*?(?:\n|\r\n?))
my @ext_blks = $data =~ m/
    ----.*?((?:TDDFT|TDDFT\/TDA|CIS|RPA))\ Excitation\ Energies.*?----
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    ----------------
/smxg;
die "no Excitation data found\n" if scalar @ext_blks == 0;
#print foreach @ext_blks;

my @diab_ext_blks = $data =~ m/
    ----.*?((?:TDDFT|TDDFT\/TDA|CIS|RPA))\ Excitation\ Energies\ \(Diabatic\).*?----
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    ----------------
/smxg;
#die "no Excitation data found\n" if scalar @ext_blks == 0;
#print foreach @diab_ext_blks;

my @iter_blks = $data =~ m/
    ^\ Iter\ \ \ \ Rts\ Conv\ \ \ \ Rts\ Left.*?----
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    ----------------
/smxg;
#die "no Iteration data found\n" if (scalar @ext_blks - scalar @diab_ext_blks) != 2*(scalar @iter_blks);
### DEBUG
#print foreach @iter_blks;


my @ptss_blks = $data =~ m/
   ^\ ----------------\ SUMMARY\ OF\ LR-PCM\ AND\ SS-PCM.*?---
   (?:\n|\r\n?)    # looking forward to newline character
   (.*?)           # coordinate block
   ----------------
/smxg;
### DEBUG
#print foreach @ptss_blks;


my @blk_index = @states;
my $size_blks = scalar @ext_blks;
#my $init_blks = 0;
if (scalar @blk_index == 0) {

    for (my $i=1; $i<=$size_blks/2; $i++) {
	push @blk_index,$i;
    }
    #print @blk_index;
}

print "\n";
#for (my $i=$init_blks; $i<$size_blks; $i=$i+2) {
foreach my $i (@blk_index) {

    my $x = ($i-1)*2;
    my $title = $ext_blks[$x];
    my $ext_data = $ext_blks[$x+1];
    my $ptss_data = $ptss_blks[$x+1];

    if ($getSS) {

    my @ptss_sets = $ptss_data =~ m/ 
    Relaxed.*?state\s*?(\d+?):.*?(?:\n|\r\n?)
    \s*?Total\ \ 1st-order\ corrected.*?energy\s*?=\s*?([-]?\d+?[.]?\d+?)\ eV(?:\n|\r\n?)
    \s*?1st-order\ SS-PCM\ corrected.*?energy.*?=\s*?([-]?\d+?[.]?\d+?)\ eV(?:\n|\r\n?)
    \s*?1st-order\ LR-PCM\ corrected.*?energy.*?=\s*?([-]?\d+?[.]?\d+?)\ eV(?:\n|\r\n?)
    \s*?0th-order\ exctition\ energy\s*?=\s*?([-]?\d+?[.]?\d+?)\ eV(?:\n|\r\n?)
#   \s*?0th-order\ excitation\ energy\s*?=\s*?([-]?\d+?[.]?\d+?)\ eV(?:\n|\r\n?)
    /smxg;
    ### DEBUG
    #print $_,"\n" foreach @ptss_sets;
    
    printf "| ### | Tot | SS | LR | 0th \n";
    for (my $n=0; $n<scalar(@ptss_sets); $n=$n+5) {
	printf "| %3d | %s | %s | %s | %s\n",
	$ptss_sets[$n],$ptss_sets[$n+1],
	$ptss_sets[$n+2],$ptss_sets[$n+3],$ptss_sets[$n+4];
    }

    }else{

    my ($num_iters,$num_trials) = compute_trial_vectors($iter_blks[$i-1]);
    printf "(%2d) == %s == / Iter: %d / Trials: %d\n",$i,$title,$num_iters,$num_trials;

    my @ext_sets = $ext_data =~ m/
    Excited\ state.*?(\d+?):\ excitation\ energy.*?([-]?\d+?[.]?\d+?)(?:\n|\r\n?)
    \s*?Total\ energy\ for.*?:\s*?([-]?\d+?[.]?\d+?)(?:\n|\r\n?)
    \s*?Multiplicity:\ (\D+?)(?:\n|\r\n?)
    \s*?Trans\.\ Mom\.:\s*?(.*?)(?:\n|\r\n?)
    \s*?Strength\ \ \ :\s+(.*?)(?:\n|\r\n?)
    /smxg;
    ### DEBUG
    #print $_,"\n" foreach @ext_sets;
    for (my $n=0; $n<scalar(@ext_sets); $n=$n+6) {
	my @mom = $ext_sets[$n+4] =~ m/
	\s*?([-]?\d+?[.]?\d+?)\s*?X\s*?([-]?\d+?[.]?\d+?)\s*?Y\s*?([-]?\d+?[.]?\d+?)\s*?Z
	/smxg;
	#print $_,"\n" foreach @mom;
	my $absmom = sqrt($mom[0]*$mom[0] + $mom[1]*$mom[1] + $mom[2]*$mom[2])*2.54174630771028;
	if ($doTot) {
#  	    printf "| %3d | %s | %s|%s |%8.4f D | %s\n",
#	    $ext_sets[$n],$ext_sets[$n+2],$ext_sets[$n+3],$ext_sets[$n+4],$absmom,$ext_sets[$n+5];
	    printf "| %3d | %s (%7.0f) | %s|%s |%8.4f D | %s\n",
	    $ext_sets[$n],$ext_sets[$n+1],($ext_sets[$n+1]*QChemConst::EV_TO_WAVENUMBERS),
	    $ext_sets[$n+3],$ext_sets[$n+4],$absmom,$ext_sets[$n+5];
        } else {
	    printf "| %3d | %s (%7.2f nm) | %s|%s |%8.4f D | %s\n",
	    $ext_sets[$n],$ext_sets[$n+1],1e7/($ext_sets[$n+1]*QChemConst::EV_TO_WAVENUMBERS),
	    $ext_sets[$n+3],$ext_sets[$n+4],$absmom,$ext_sets[$n+5];
	}
    }

    }

    print "\n";
}

sub compute_trial_vectors
{
    my $iter_data = shift;
    my @iters = $iter_data =~ m/
    ^\s+?\d+\s+?\d+\s+?(\d+).*?(?:\n|\r\n?)
    #^\s+?(\d+)\s+?(\d+)\s+?(\d+).*?(?:\n|\r\n?)
    /smxg;
    #print foreach @lines;
    my $num_iters  = scalar @iters;
    my $num_trials = 0;
    foreach (@iters){
        $num_trials += $_;
    }
    return ($num_iters,$num_trials);
}
