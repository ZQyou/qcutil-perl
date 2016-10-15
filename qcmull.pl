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
use QParse;

### variables for commandline parsing.
my @secs = ();
my $doBecke = 0;
### parse commandline arguments
GetOptions( 
    'becke|b'     => \$doBecke,
    'sec|s=s{,}'  => \@secs
); 
  
die "Usage: ".basename($0)." <file> <num_mul> [ -b ] [ -s sec1 sec2 ] .. \n" unless scalar @ARGV > 0;

my ($qcout,$whichone) = @ARGV;

my $qparse = QParse->new($qcout);
my @mulls = ($doBecke) ? $qparse->charges('becke'=>1) : $qparse->charges();

my $num_mulls = scalar @mulls;

die "$num_mulls Charge-Spin blocks found \n" if ! defined $whichone or $whichone < 1 or $whichone > $num_mulls;

# use request charges
my $whichmull = $mulls[$whichone-1];
my $dospin = ( @{$whichmull->{spin}} > 0 ) ? 1 : 0;

my $tol_chg = 0;
my $tol_spin = 0;

$tol_chg += $_ foreach (@{$whichmull->{chg}});

if ($dospin)
{
    $tol_spin += $_ foreach (@{$whichmull->{spin}});
}

if (scalar @secs > 0) {

    my $kk = 0;
    my $tol_seg_chg = 0.0;
    my $tol_seg_spin = 0.0;

    print "\n";
    foreach (@secs)
    {
	my ($s,$e) = split /-/,$_;
	next if $s > $whichmull->{num} || $e > $whichmull->{num} ;

        $kk++;
        my $seg_chg = 0.0;
        my $seg_spin = 0.0;

        for(my $i=$s; $i<=$e; $i++)
        {
            $seg_chg += $whichmull->{chg}[$i-1];
            $seg_spin += $whichmull->{spin}[$i-1] if $dospin;
        }

        $tol_seg_chg += $seg_chg;
        $tol_seg_spin += $seg_spin if $dospin;

        printf "Segment%2s (%3s-%3s): %12.6f  %12.6f\n",$kk,$s,$e,$seg_chg,$seg_spin;
    }
    printf "Total Segment Stat.: %12.6f  %12.6f\n",$tol_seg_chg,$tol_seg_spin;
}
else {
    my $header = ($doBecke) ? 'Becke Population' : 'Mulliken Population';
    printf "\t$header\n";
    print $whichmull->{mull};   
}

print "\n";
printf "  Total Charge: %12.6f\n", $tol_chg;
printf "  Total Spin  : %12.6f\n", $tol_spin;
  
