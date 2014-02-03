#!/usr/bin/perl

use strict;

if (@ARGV < 3) {
    print STDERR "Usage: xrdfragcp  XrdServer Njobs $0 \n";
    exit 1;
}

my $server = $ARGV[0];
my $Njobs  = $ARGV[1];
my $file   = $ARGV[2]; 

open(INFO, $file) or die("Could not open file $file.");

open FILE, "<$file" or die "Could not open $file: $!\n";
my @array=<FILE>;
close FILE;

# passing xrdfragcp options
my $vread_enabled=0;
my $newcl= 0;


my $vread;
if($vread_enabled) {
  print("vread enabled\n");
  my $vread= "--vread 128"
}

my $fragcpcmd;
if ($newcl) {
  my $ldpath = "/home/alja/xrd/bld/ixrd/lib64/";
  if (-e $ldpath) {
    $ENV{"LD_LIBRARY_PATH"} = $ldpath;
    $fragcpcmd = "$ENV{HOME}/xrd/sim/xrdfragcpnew"
  }
}
else {
  $fragcpcmd = "$ENV{HOME}/xrd/sim/xrdfragcp"
}

for (my $count = 0; $count < $Njobs; $count++) {
   my $randomline=$array[rand @array];
   chomp $randomline;

   my $cmd;
   
       $cmd = "$fragcpcmd --cmsclientsim 720000000 300 3000 $vread root://$server//store/".$randomline." &";

    print (localtime, " $cmd \n");
    system(" $cmd");
    sleep(1);
#   last;
}
