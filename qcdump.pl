#!/usr/bin/env perl

use strict;
use warnings;

# define a constant for double precision size
my $DP  = 8;
my $SP  = 4;
my $INT = 4;

# test $QCSCRATCH
my $dir = $ENV{"QCSCRATCH"};
die "$dir is not a directory or not exist !\n" unless -d $dir;
#my $dir = $ENV{"PWD"};

die "Usage: qcdump.pl <run> <file> <bflag> <seek> <count> [<col>] \n" unless scalar @ARGV == 5;
my ($run,$file,$bflag,$seek,$count) = @ARGV;

my $BLCK = 0; my $bstr = "";
if ($bflag eq "DP")
{
  $BLCK = $DP; $bstr = "d";
}
if ($bflag eq "SP")
{
  $BLCK = $SP; $bstr = "f";
}
elsif ($bflag eq "INT")
{
  $BLCK = $INT; $bstr = "l";
}
else {
  exit 1;
}

my $prefix = "$dir/$run";
die "$prefix is not a directory or not exist !\n" unless -d $prefix;

#my $in = "$prefix/$file.0";
my $in = "$prefix/$file";
my $fsize = -s "$in";

$count = $fsize/$BLCK if $count == 0;
my $slen = $seek * $BLCK;
my $len = $count * $BLCK;
print "read $in ($slen + $len/$fsize bytes)\n";

open(IN, "< $in") or die "Unable to open file\n";
binmode(IN);

# sflag = 0,1,2 - SEEK_SET, SEEK_CUR, SEEK_END
my $sflag = 0;
my $buf;
seek IN, $slen, $sflag;
read IN, $buf, $len;
my @data = ();
@data = unpack "l[$count]", $buf if $bstr eq "l";
@data = unpack "d[$count]", $buf if $bstr eq "d";
@data = unpack "f[$count]", $buf if $bstr eq "f";
close(IN);

prtmat(@data);

sub prtmat
{
  my @mat = @_;
  my $count = 0;
  my $col = 6;
  foreach my $num (@mat)
  {
    $count++;
    print "\n" if $count > $col;
    $count = 1 if $count > $col;
    printf " %14.7E",$num;
  }
  print "\n";
}

