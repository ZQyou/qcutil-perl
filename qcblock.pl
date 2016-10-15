#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;

die "Usage: ".basename($0)." <qcout> [cut]\n" unless scalar @ARGV >= 1;

my $fname = shift @ARGV;
my $fsize = -s "$fname";

my $data;

open TMP, "<$fname" or die "$fname: $!\n";
read TMP, $data, $fsize;
close TMP;

my $docut = 0;
$docut = 1 if scalar @ARGV >=1 and shift @ARGV eq "cut";

my @blocks = $data =~ m/
    (MemMan::.*?\(\).*?(?:\n|\r\n?)) 
    #(?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    (Size\ of\ BlockTensors\ scheduled.*?(?:\n|\r\n?))
    (^.*?(?:\n|\r\n?))
/smxg;

#print "Remove the number of blocks: ".( scalar @blocks / 4)."\n";

die "no data found\n" if scalar @blocks == 0;

if ($docut) {
  $data =~ s/
    (MemMan::.*?\(\).*?(?:\n|\r\n?)) 
    #(?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    (Size\ of\ BlockTensors\ scheduled.*?(?:\n|\r\n?))
    (^.*?(?:\n|\r\n?))
  //smxg;

  print "Remove the number of blocks: ".( scalar @blocks / 4)."\n";

  my $output = "$fname";
  open OUT, ">$output" or die "$output: $!\n";
  print OUT $data;
  close OUT;
} else {
  # DEBUG
  #print foreach @blocks;
  #print scalar @blocks, "\n";
  print $blocks[0],$blocks[1],$blocks[2],$blocks[3];
}
