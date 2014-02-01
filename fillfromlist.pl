#!/usr/bin/perl

use List::Util qw/shuffle/;
use strict;
use warnings;

my $Njobs = 50;
my $file =  $ARGV[0];
open(INFO, $file) or die("Could not open file $file.");

my @urls;
my $line;
my $fex='OK root\:\/\/xrootd\.unl\.edu(.*)';
foreach $line (<INFO>)  
{ if ($line =~ /$fex/)
  {
    push(@urls, $1);
  }
}

my @shuffled_indexes = shuffle(0..$#urls);
my @pick_indexes = @shuffled_indexes[ 0 .. $Njobs ];  
my @picks = @urls[ @pick_indexes ];

foreach (@picks) {
    my $cmd = "/home/alja/xrd/sim/xrdfragcp --cmsclientsim 720000000 300 3000 root://xrootd-proxy.t2.ucsd.edu:7111".$_." &";
    print (localtime, " $cmd \n");
    system(" $cmd");
    sleep(3);
}
