#!/usr/bin/perl

use strict;

if (@ARGV < 2) {
    print STDERR "Usage: $0 Njobs\n";
    exit 1;
}

my $file =  $ARGV[0];
my $Njobs = $ARGV[1];

open(INFO, $file) or die("Could not open file $file.");

open FILE, "<$file" or die "Could not open $file: $!\n";
my @array=<FILE>;
close FILE;


for (my $count = 0; $count < $Njobs; $count++) {
   my $randomline=$array[rand @array];
   chomp $randomline;

   my $cmd = "$ENV{HOME}/xrd/sim/xrdfragcp --cmsclientsim 720000000 300 3000 --vread 128 root://xrootd-proxy.t2.ucsd.edu//store/".$randomline." &";

   print (localtime, " $cmd \n");
    system(" $cmd");
    sleep(3);
#   last;
}
