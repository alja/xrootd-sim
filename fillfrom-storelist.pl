#!/usr/bin/perl

use strict;


use Getopt::Long;

if (@ARGV < 3) {
    print STDERR "Usage: xrdfragcp  --server=<> --jobs<> --file<> --vread=<int> --verbose --newcl --sleep<int> \n";
    exit 1;
}

my $server  = "";
my $jobs   = "0";
my $file    = "";
my $verbose = "";
my $vread   = "";
my $randfrag   = "";
my $ordered   = 0;
my $newcl= 0;
my $sleepTime = 2;
my $list_offset = 0;
my $list_size = 0;
my $tried = "";



my $sim_path = "$ENV{HOME}/xrd/sim";


my $result = GetOptions ("server=s" => \$server,
                       "jobs=i"   => \$jobs,
                       "file=s"   => \$file, 
                       "vread=i"   => \$vread,
                       "sleep=i"   => \$sleepTime,
                       "list_offset=i"   => \$list_offset,
                       "list_size=i"   => \$list_size,
                       "newcl"   => \$newcl,
                       "randfrag"   => \$randfrag,
                       "ordered"  => \$ordered,      
                       "tried=s"  => \$tried,                  
                       "verbose"  => \$verbose);



open(INFO, $file) or die("Could not open file $file.");

open FILE, "<$file" or die "Could not open $file: $!\n";
my @array=<FILE>;
close FILE;

if (!$list_size)
{
  $list_size = @array;
}

if ($verbose) {
  $verbose = "--verbose";
}

if($vread) {
  print("vread enabled\n");
  $vread=" --vread $vread";
}

if ($randfrag){
  print("random ragment offsets enabled\n");
  $randfrag ="--random";
}

if ($tried){
  $tried = "?tried=".$tried;
}
my $fragcpcmd;
if ($newcl) {
  my $ldpath = "/home/alja/xrd/bld/ixrd/lib64/";
  if (-e $ldpath) {
    $ENV{"LD_LIBRARY_PATH"} = $ldpath;
    $fragcpcmd = "$sim_path/xrdfragcpnew";
  }
}
else {
  $fragcpcmd = "$sim_path/xrdfragcp";
}

for (my $count = 0; $count < $jobs; $count++) {
  my $line_idx;
  if ($ordered) {
    $line_idx = $count;
  }
  else {
    $line_idx = rand $list_size;
  }

  $line_idx += $list_offset;

  my $line =$array[$line_idx]; #rand @array];
  chomp $line;

$line=~s/\s+$//;
  my $cmd;

  $cmd = "$fragcpcmd --cmsclientsim 720000000 300 3000 $vread $verbose $randfrag root://$server//store/".$line.$tried." &";

  print (localtime, " $cmd \n");
  system(" $cmd");
  sleep($sleepTime);
#   last;
}
