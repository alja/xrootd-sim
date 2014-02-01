#!/usr/bin/perl

use strict;
my $Njobs = 5;
my $file =  $ARGV[0];
open(INFO, $file) or die("Could not open file $file.");

open FILE, "<$file" or die "Could not open $file: $!\n";
my @array=<FILE>;
close FILE;


for (my $count = 0; $count < 50; $count++) {
   my $randomline=$array[rand @array];
   chomp $randomline;

   my $cmd = "/home/alja/xrd/sim/xrdfragcp --cmsclientsim 720000000 300 3000 --vread 128 root://xrootd-proxy.t2.ucsd.edu//store/".$randomline." &";

   print (localtime, " $cmd \n");
    system(" $cmd");
    sleep(1);
#   last;
}
