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

### variables for commandline parsing.
my $fname = "";
my $num_batch = 0;
my $n_mo = 0;
my @secs = ();
my $verbose;
### parse commandline arguments
GetOptions( "file|f=s"    => \$fname,
	    "num|n=i"     => \$num_batch,
	    "mo|mo=i"     => \$n_mo,
 	    "sec|s=s{,}"  => \@secs)
  or die "Usage: ".basename($0)." -f <file> -n <num_mul> [ -b ] -s [ sec1 ] [ sec2 ] .. \n";
#my ($fname,$num_batch,@secs) = @ARGV;

die "Usage: ".basename($0)." -f <file> -n <num_mul> [ -b ] -s [ sec1 ] [ sec2 ] .. \n" if ! $fname;

my $fsize = -s "$fname";
open TMP, $fname or die "Sorry! Can't open this file !!\n";

my $data;
read TMP, $data, $fsize;
close TMP;

my @mull_chg_spin_blocks = ();
my @mull_blocks = ();

@mull_blocks = $data =~ m{
    Partial\ Mulliken\ Populations.*?(?:\n|\r\n?)
    ^$
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    ^\s$
}smxg;
### DEBUG
#print scalar @mull_blocks,"\n";
#print $_,"\n" foreach @mull_blocks;
#print  pop @mull_blocks;

my $num_blks = scalar @mull_blocks;

# -- read each partial mulliken popluation
my $mull_batch;
my @idxs = ();
my @atms = ();
my @shls = ();
my @ppls = ();
my $nbas = 0;
if ($num_batch <= $num_blks and $num_batch > 0) {

   $mull_batch = $mull_blocks[$num_batch-1];
   #print $mull_batch;

   my @mo_headers = $mull_batch =~ m{
       ^\s{10,}(\d+\s+.*?)
       (?:\n|\r\n?)
   }smxg;
   my $num_mo_blks = scalar @mo_headers;
   my @moidx = ();
   @moidx = (@moidx,(split /\s+/,$_)) foreach @mo_headers;
   my $HOMO = pop @moidx;
   $n_mo = $HOMO if $n_mo < 0 or $n_mo > $HOMO;

   if ($n_mo) {
       # -- find in which block 
       my $iblk = int ( ($n_mo-1)/6 );
       my @mo_lines = $mull_batch =~ m{
           (^\s+\d+\s+[A-Z]+[a-z]?\s?\d+.*?)
           (?:\n|\r\n?)
       }smxg;
       $nbas = scalar @mo_lines  / $num_mo_blks;
       for (my $i=$iblk*$nbas ; $i<$nbas*($iblk+1) ; $i++) {
	   $mo_lines[$i] =~ s/^\s+//g;
	   my @tmp = split /\s\s+/, $mo_lines[$i];
	   @idxs = (@idxs,$tmp[0]);
	   @atms = (@atms,$tmp[1]);
	   @shls = (@shls,$tmp[2]);
	   @ppls = (@ppls,$tmp[ ($n_mo-1)%6 +3 ]);
       }
       #print $_,"\n" foreach @atms;
   } else {
       #print $mull_batch;
       print "\n HOMO = ", $HOMO,"\n";
   }

}
else { print $num_blks,"\n";  exit 1; }
 
my $tol_ppls = 0;
$tol_ppls += $_ foreach @ppls;

#s/\D+//g foreach @atms;
#print $_,"\n" foreach @atms;

for (my $i=0; $i<$nbas; $i++) {
    print "$idxs[$i]\t$atms[$i]\t$shls[$i]\t$ppls[$i]\n";
}

if (scalar @secs > 0) {
  my $kk = 0;
  my $tol_seg_ppls = 0.0;

  print "\n";
  foreach (@secs)
  {
    my ($s,$e) = split /-/,$_;

    next if $s > $nbas || $e > $nbas ;

    $kk++;
    my $seg_ppls = 0.0;

    for (my $i=$s; $i<=$e; $i++)
    {
      $seg_ppls += $ppls[$i-1];
    }

    $tol_seg_ppls += $seg_ppls;

    printf "Segment%2s (%3s-%3s): %12.6f\n",$kk,$s,$e,$seg_ppls;
  }
  printf "Total Segment State: %12.6f\n",$tol_seg_ppls;
}
#else { print $mull_blocks[$num_batch-1]; }

print "\n";
printf "  Total Population: %12.6f\n", $tol_ppls;
