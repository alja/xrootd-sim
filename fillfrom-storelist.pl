#!/usr/bin/perl

use strict;


use Getopt::Long;

if (@ARGV < 3) {
    print STDERR "Usage: xrdfragcp  --server=<> --jobs<> --file<> --vread=<int> verbose newcl \n";
    exit 1;
}

my $server  = "";
my $jobs   = "0";
my $file    = "";
my $verbose = "";
my $vread   = 0;
my $newcl= 0;

my $sim_path = "$ENV{HOME}/xrd/sim";


my $result = GetOptions ("server=s" => \$server,
                       "jobs=i"   => \$jobs,
                       "file=s"   => \$file,      # string
                       "vread=i"   => \$vread,      # string
                       "newcl"   => \$newcl,      # string
                       "verbose"  => \$verbose);  # flag



open(INFO, $file) or die("Could not open file $file.");

open FILE, "<$file" or die "Could not open $file: $!\n";
my @array=<FILE>;
close FILE;


if ($verbose) {
  $verbose = "--verbose";
}

if($vread) {
  print("vread enabled\n");
  $vread=" --vread $vread";
}

my $fragcpcmd;
if ($newcl) {
  my $ldpath = "/home/alja/xrd/bld/ixrd/lib64/";
  if (-e $ldpath) {
    $ENV{"LD_LIBRARY_PATH"} = $ldpath;
    $fragcpcmd = "$sim_path/xrdfragcpnew"
  }
}
else {
  $fragcpcmd = "$sim_path/xrdfragcp"
}

for (my $count = 0; $count < $jobs; $count++) {
   my $randomline=$array[rand @array];
   chomp $randomline;

   my $cmd;
   
   $cmd = "$fragcpcmd --cmsclientsim 720000000 300 3000 $vread $verbose root://$server//store/".$randomline." &";

    print (localtime, " $cmd \n");
  #  system(" $cmd");
    sleep(2);
#   last;
}
