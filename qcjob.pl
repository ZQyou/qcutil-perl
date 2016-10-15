#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use Getopt::Long;

use lib dirname($0);
use QParse;

die "Usage: ".basename($0)." <qcout> job_number\n" unless scalar @ARGV >= 1;

my ($qcout,$whichone) = @ARGV;
my $qparse = QParse->new($qcout);

my @jobs = $qparse->jobs();
my $num_jobs = scalar @jobs;

die "$num_jobs Qchem jobs found\n" if ! defined $whichone or $whichone < 1 or $whichone > $num_jobs;

print $jobs[$whichone-1];
