#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use File::Basename;
use Date::Parse;

use lib $ENV{"HOME"}."/qcutil";
use QParse;
use QParseLib;

my $onlySec = 0;
GetOptions( 'sec|b'  => \$onlySec
          );

die "Usage: ".basename($0)." [ -sec ] <qcout>\n" unless scalar @ARGV >= 1;

my $fname = shift @ARGV;
my $qparse = QParse->new($fname);
my @times = $qparse->times();

## debug
#print $_,"\n" foreach @times;
#exit;

exit if scalar @times < 1;

my $host  = $times[1];
my $sdate = $times[0];

my $edate = $times[2];

if ($onlySec) {
  my $jobsec =  str2time($edate) - str2time($sdate);
  printf "%s sec\n",$jobsec;

} else {
  print "$host\n";
  print "Started  on $sdate\n";
  print "Finished on $edate\n";
  my $jobsec =  str2time($edate) - str2time($sdate);
  printf "%s secs\n%.2f mins\n%.2f hours\n",$jobsec,$jobsec/60,$jobsec/60/60;
}
