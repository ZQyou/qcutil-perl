#!/usr/bin/perl

# define a constant for double precision size
$DP = 8;
$INT = 4;

# test $QCSCRATCH
my $dir = $ENV{"QCSCRATCH"};
die "$dir is not a directory or not exist !\n" unless -d $dir;

die "Usage: qcdump.pl <run> <file> <bflag> data[] \n" unless scalar @ARGV > 3;
my ($run,$file,$bflag,@data) = @ARGV;

my $BLCK = 0; my $bstr = "";
if ($bflag eq "DP")
{
  $BLCK = $DP; $bstr = "d";
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

my $out = "$prefix/$file.0";
my $count = scalar @data;
my $dsize = $count * $BLCK;
print "write $out ($dsize bytes)\n";

#$slen = $seek * $DP;
#$len = $count * $DP;

open(OUT, "> $out") or die "Unable to open file\n";
binmode(OUT);

#seek OUT, $slen, $sflag;
#print OUT pack("l[$count]",@data) if $bflag == "INT";
#print OUT pack("d[$count]",@data) if $bflag == "DP";
print OUT pack "$bstr", $_ foreach (@data);

close OUT;

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

