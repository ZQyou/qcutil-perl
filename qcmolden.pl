#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;

die "Usage: ".basename($0)." <qcout> [q2v|cutmo|cut|vmd|esp|pqr|pqr2|tri]\n" unless scalar @ARGV >= 1;

my $fname = shift @ARGV;
my $fsize = -s "$fname";

my $data;

open TMP, "<$fname" or die "$fname: $!\n";
read TMP, $data, $fsize;
close TMP;

my $myarg = 0;
$myarg = shift @ARGV if scalar @ARGV >=1;
my $docut = 0;
my $domo  = 0;
my $dovmd = 0;
my $doq2v = 0;
my $doesp = 0;
my $dopqr = 0;
my $dopqr2 = 0;
my $dotri  = 0;
$docut = 1 if $myarg eq "cut";
if ($myarg eq "cutmo") {
  $docut = 1; $domo = 1;
}

$dovmd = 1 if $myarg eq "vmd";
$doq2v = 1 if $myarg eq "q2v";
$dopqr = 1 if $myarg eq "pqr";
if ($myarg eq "pqr2") {
  $dopqr = 1; $dopqr2 = 1;
}
$doesp = 1 if $myarg eq "esp";
$dotri = 1 if $myarg eq "tri";

if ($doq2v) {
  $data =~ s/SP\ /sp /smxg;
  $data =~ s/S\ /s /smxg;
  $data =~ s/P\ /p /smxg;
  $data =~ s/D\ /d /smxg;
  $data =~ s/F\ /f /smxg;
#  $data =~ s/E\+/D\+/smxg;
#  $data =~ s/E-/D-/smxg;
  $data =~ s/Sym=.*?(?:\n|\r\n?)//smxg;
  print $data;
  exit 0;
}

my @molden_blks = $data =~ m/
    ^=======.*?MOLDEN.*?FORMAT.*?=======
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    =======\ END\ OF\ MOLDEN-FORMAT.*?=======
/smxg;

#my @molden_blks = $data =~ m/
#    =======\ MOLDEN-FORMATTED\ INPUT\ FILE\ FOLLOWS\ =======
#    (?:\n|\r\n?)    # looking forward to newline character
#    (.*?)           # coordinate block
#    =======\ END\ OF\ MOLDEN-FORMATTED\ INPUT\ FILE\ =======
#/smxg;

my @pqr_blks = $data =~ m/
    ^\ -----\ Tesselation\ \.PQR\ file\ -----.*?
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    ^\ -----\ End\ of\ Tesselation\ .PQR\ file\ -----
/smxg;

my @esp_blks = $data =~ m/
    ^\ -----\ Cavity\ ESP\ \.PQR\ file\ -----.*?
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    ^\ -----\ End\ of\ Cavity\ ESP\ .PQR\ file\ -----
/smxg;

my @tri_blks = $data =~ m/
    ^\ -------------\ Begin\ Surface\ (?:charge|potential)\ triangulation\ -----.*?
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    ^\ -------------\ End\ Surface\ (?:charge|potential)\ triangulation\ -------------
/smxg;
#print $tri_blks[1],"\n\n\n\n",$tri_blks[0];

die "no MOLDEN, QR, ESP and Triangulation data found\n" 
if scalar @molden_blks == 0 && scalar @pqr_blks == 0 && scalar @esp_blks == 0 && scalar @tri_blks == 0;

=begin SECTION_TEST  
if ($docutmo) {
  my @atoms_sec;
  my @basis_sec;
  my @mo_sec;

  my $filenum = 1;
  foreach my $molden (@molden_blks) {
    @atoms_sec = $molden =~ m/
      (^\[Atoms\].*?)
      ((?:\n|\r\n?))	# looking forward to newline character - save it !!
      (.*?)		# coordinate block
      ^\[[GS]TO\]
    /smxg;
  
    @basis_sec = $molden =~ m/
      (^\[[GS]TO\].*?)
      ((?:\n|\r\n?))	# looking forward to newline character - save it !!
      (.*?)		# coordinate block
      ^\[MO\]
    /smxg;
  
    @mo_sec = $molden =~ m/
      (^Sym=.*?)
      ((?:\n|\r\n?))	# looking forward to newline character - save it !!
      (.*?)		# coordinate block
      ^Sym
    /smxg;
    # DEBUG
    #print foreach @atoms_sec;
    #print foreach @basis_sec;
    #print "[MO]\n";
    #print foreach @mo_sec;
  }
}
=end SECTION_TEST
=cut

##################################
### PQR
##################################
if ($dopqr) {
  ### dump pqr output
  my $cutpqr = "$fname.pqr";
  if (scalar @pqr_blks > 1) {
    my $filnum = 1;	  
    foreach my $blk (@pqr_blks) {
      print "PQR data_$filnum is dumped into $cutpqr.$filnum\n";
      if ($dopqr2) {
	pqr2("$cutpqr.$filnum",$blk);
      } else {
        open CUT, ">$cutpqr.$filnum" or die "$cutpqr.$filnum: $!\n";
        print CUT $blk;
        close CUT;
      }
      $filnum++;
    }
  } else {	    
    my $blk = $pqr_blks[0];
    print "PQR data is dumped into $cutpqr\n";
    if ($dopqr2) {
      pqr2($cutpqr,$blk);
    } else {
      open CUT, ">$cutpqr" or die "$cutpqr: $!\n";
      print CUT $blk;
      close CUT;
    }
  }

  ### clear up 
  $data =~ s/
    ^\ -----\ Tesselation\ \.PQR\ file\ -----.*?
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    ^\ -----\ End\ of\ Tesselation\ \.PQR\ file\ -----
  //smxg;

  ### dump qchem output
  my $output = "$fname";
  open OUT, ">$output" or die "$output: $!\n";
  print OUT $data;
  close OUT;
  ### DEBUG
  #print $data;

##################################
### Surface triangulation
##################################
} elsif ($dotri) {
  ### dump tri output
  my $cuttri = "$fname.tri";
  if (scalar @tri_blks > 1) {
    my $filnum = 1;	  
    foreach my $blk (@tri_blks) {
      print "Triangulation data_$filnum is dumped into $cuttri.$filnum\n";
      open CUT, ">$cuttri.$filnum" or die "$cuttri.$filnum: $!\n";
      print CUT $blk;
      close CUT;
      $filnum++;
    }
  } else {	    
    my $blk = $tri_blks[0];
    print "Triangulation data is dumped into $cuttri\n";
    open CUT, ">$cuttri" or die "$cuttri: $!\n";
    print CUT $blk;
    close CUT;
  }

  ### clear up 
  $data =~ s/
    ^\ -------------\ Begin\ Surface\ (?:charge|potential)\ triangulation\ -----.*?
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    ^\ -------------\ End\ Surface\ (?:charge|potential)\ triangulation\ -------------
  //smxg;

  ### dump qchem output
  my $output = "$fname";
  open OUT, ">$output" or die "$output: $!\n";
  print OUT $data;
  close OUT;
  ### DEBUG
  #print $data;

##################################
### ESP
##################################
} elsif ($doesp) {
  ### dump esp output
  my $cutesp = "$fname.esp";
  if (scalar @esp_blks > 1) {
    my $filnum = 1;	  
    foreach my $blk (@esp_blks) {
      print "ESP data_$filnum is dumped into $cutesp.$filnum\n";
      open CUT, ">$cutesp.$filnum" or die "$cutesp.$filnum: $!\n";
      print CUT $blk;
      close CUT;
      $filnum++;
    }
  } else {	    
    my $blk = $esp_blks[0];
    print "ESP data is dumped into $cutesp\n";
    open CUT, ">$cutesp" or die "$cutesp: $!\n";
    print CUT $blk;
    close CUT;
  }

  ### clear up 
  $data =~ s/
    ^\ -----\ Cavity\ ESP\ \.PQR\ file\ -----.*?
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    ^\ -----\ End\ of\ Cavity\ ESP\ \.PQR\ file\ -----
  //smxg;

  ### dump qchem output
  my $output = "$fname";
  open OUT, ">$output" or die "$output: $!\n";
  print OUT $data;
  close OUT;
  ### DEBUG
  #print $data;

} elsif ($docut) {

  ### dump molden output
  my $cutmld = "$fname.mld";
  if (scalar @molden_blks > 1) {
    my $filnum = 1;	  
    foreach my $blk (@molden_blks) {
      print "MOLDEN data_$filnum is dumped into $cutmld.$filnum\n";
      open CUT, ">$cutmld.$filnum" or die "$cutmld.$filnum: $!\n";
      $blk =~ s{ ^ \n \z }{}xms;	# remove the last blank line
      $blk =~ s/Beta/Alpha/smxg if $domo;
      print CUT $blk;
      close CUT;
      $filnum++;
    }
  } else {	    
    my $blk = $molden_blks[0];
    print "MOLDEN data is dumped into $cutmld\n";
    open CUT, ">$cutmld" or die "$cutmld: $!\n";
    $blk =~ s{ ^ \n \z }{}xms;		# remove the last blank line
    $blk =~ s/Beta/Alpha/smxg if $domo;
    print CUT $blk;
    close CUT;
  }

  ### clear up 
  $data =~ s/
    ^=======.*?MOLDEN.*?FORMAT.*?=======
    (?:\n|\r\n?)    # looking forward to newline character
    (.*?)           # coordinate block
    =======\ END\ OF\ MOLDEN-FORMAT.*?=======
  //smxg;

  ### dump qchem output
  my $output = "$fname";
  open OUT, ">$output" or die "$output: $!\n";
  print OUT $data;
  close OUT;
  ### DEBUG
  #print $data;

} elsif ($dovmd) {

  my $blk = $molden_blks[0];
  $blk =~ s{ ^ \n \z }{}xms;		# remove the last blank line
  $blk =~ s/Beta/Alpha/smxg if $domo;
  $blk =~ s/SP\ /sp /smxg if $dovmd;
  $blk =~ s/S\ /s /smxg if $dovmd;
  $blk =~ s/P\ /p /smxg if $dovmd;
  $blk =~ s/D\ /d /smxg if $dovmd;
  $blk =~ s/F\ /f /smxg if $dovmd;
#  $blk =~ s/E\+/D\+/smxg if $dovmd;
#  $blk =~ s/E-/D-/smxg if $dovmd;
  $blk =~ s/Sym=.*?(?:\n|\r\n?)//smxg if $dovmd;
  my @lines = $blk =~ m/
    (.*?)           # coordinate block
    (?:\n|\r\n?)    # looking forward to newline character
  /smxg;
  print $blk;
=begin LOWER_PRECISION
  foreach (@lines) {
    if (/^\s+\d+\s+.*(?:e\+|e-)\d+/) {
      s/^\s+//g;
      my @mo = split /\s+/,$_;
      printf "%4d %10.6f\n", $mo[0],$mo[1]; 
    } else {
      print $_,"\n";
    }
  }
=end LOWER_PRECISION
=cut

} elsif ($myarg =~ /\d+/ and $myarg <= scalar @molden_blks and $myarg > 0) {

  my $blk = $molden_blks[$myarg-1];	
  $blk =~ s{ ^ \n \z }{}xms;		# remove the last blank line
  print $blk;

} else {
  # DEBUG
  #print foreach @molden_blks;
  #print foreach @pqr_blks;
  printf "%3d MOLDENs found\n", scalar @molden_blks;
  printf "%3d PQRs found\n", scalar @pqr_blks;
  printf "%3d ESPs found\n", scalar @esp_blks;
  printf "%3d Triangulation found\n", scalar @tri_blks;
}

# {{{ pqr2 function
sub pqr2 {
  my $file = shift;
  open CUT, ">$file" or die "$file: $!\n";

  my $pqrdata = shift;
  my @lines = $pqrdata =~ m{
     (.*?)(?:\n|\r\n?)
  }smxg;

  print CUT "REMARK   1 PQR\n";
  
  my $new = "";
  foreach (@lines)
  {
    s/^\s*//g;
    my @v = split /\s+/, $_;
    
    ## $v[8] = number of electrons
    $new = sprintf("%-6s%5d %4s %3s  %4d    %8.3f%8.3f%8.3f %10.6f %8.6f\n",
                    $v[0],$v[1],$v[2],$v[3],$v[4],$v[6],$v[7],$v[8],$v[9]*-1,$v[10]);
    #print $new;
    print CUT $new;
  }

  close CUT;
}
# }}}
