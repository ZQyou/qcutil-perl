#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

my $scalFac = 1;
my $doCen = 0;
GetOptions( 
    'scale|s=f'	=> \$scalFac,
    'cen|b'     => \$doCen
);

my $narg = scalar @ARGV;
die "Usage: ".basename($0)." [ -s scale_factor ] [ -cen ] <file>\n" if $narg != 1;

my $data;
if ($narg == 1){
   my $fname = shift @ARGV;
   my $size = -s $fname;
   open TMP,'<',$fname or die "$fname: $!\n";
   read TMP, $data, $size;
   close TMP;
}

my @header = $data =~ m{
	(.*?)(?:\n|\r\n?)	# title
	(^\d+?)(?:\n|\r\n?)	# number of atoms
	.*
	(^\s+\d+[.]?\d+\s+\d+[.]?\d+\s+\d+[.]?\d+$)
}smxg;
#print scalar @header;

my ($ox,$oy,$oz) = (0,0,0);
if ($doCen){
   ($ox,$oy,$oz) = $header[2] =~ m{
 	(\s+\d+[.]?\d+)(\s+\d+[.]?\d+)(\s+\d+[.]?\d+)
   }smxg;
   ($ox,$oy,$oz) = ($ox*0.5,$oy*0.5,$oz*0.5);
   #print $ox,$oy,$oz,"\n";
}

my @grodata = $data =~ m{
	^\s*?\d+?[A-Z]+?\s*?[A-Z]+?\d?\s*?\d+?
        \s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+
        \s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+
	\s*(?:\n|\r\n?)
}smxg;
#print "$_" foreach @grodata;

printf "%s\n%s\n", $header[0],$header[1];
my @xyz = ();
my ($rx,$ry,$rz) = (0,0,0);
my ($nx,$ny,$nz) = (0,0,0);
my $mscalFac = 1-$scalFac;
foreach my $line (@grodata){

   @xyz = $line =~ m{
	(^\s*?\d+?[A-Z]+?)(\s*?[A-Z]+?\d?\s*?\d+?)
        (\s+[-]?(?:\d?|\d+)[.]?\d+)(\s+[-]?(?:\d?|\d+)[.]?\d+)(\s+[-]?(?:\d?|\d+)[.]?\d+)
        (\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+\s+[-]?(?:\d?|\d+)[.]?\d+)
   }smxg;
   #print @xyz,"\n";

   if ($xyz[1] =~ "OW"){
      ($nx,$ny,$nz) = ($xyz[2],$xyz[3],$xyz[4]);
      ($rx,$ry,$rz) = (($nx-$ox)*$mscalFac,($ny-$oy)*$mscalFac,($nz-$oz)*$mscalFac);
      ($nx,$ny,$nz) = ($nx-$rx,$ny-$ry,$nz-$rz);
      printf "%s%s%8.3f%8.3f%8.3f%s\n", $xyz[0],$xyz[1],$nx,$ny,$nz,$xyz[5];
   }else{
      ($nx,$ny,$nz) = ($xyz[2]-$rx,$xyz[3]-$ry,$xyz[4]-$rz);
      printf "%s%s%8.3f%8.3f%8.3f%s\n", $xyz[0],$xyz[1],$nx,$ny,$nz,$xyz[5];
   }
}
printf "%s\n",$header[2];
