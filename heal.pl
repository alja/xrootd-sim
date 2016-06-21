#!/usr/bin/perl

use strict;




use Getopt::Long;
use File::Basename;

if (@ARGV < 2) {
    print STDERR "Usage: xrdfragcp   --file<> --verbose \n";
    exit 1;
}
# ./heal.pl --file=ten.txt --jobs=3 --list_offset=2

my $jobs   = "0";
my $file    = "";
my $verbose = "";
my $list_offset = 0;

my $result = GetOptions ( "file=s"   => \$file,
                          "jobs=i"   => \$jobs,
                          "list_offset=i"   => \$list_offset,
                          "verbose"  => \$verbose);


open(INFO, $file) or die("Could not open file $file.");

open FILE, "<$file" or die "Could not open $file: $!\n";
my @array=<FILE>;
close FILE;

my $blocksize = 1024*1024*128;

for (my $count = 0; $count < $jobs; $count++) {

   my $line_idx = $count;
   $line_idx += $list_offset;

   my $line =$array[$line_idx]; 
  chomp $line;

  $line=~s/\s+$//;
  my $cmd;

  my $value = `hdfs fsck  -locations -blocks -files $line` ;
  # print $value;
  print "========================\n";

  if ($value =~ /HEALTHY/) { printf ("HEALTHY $line!\n"); }; 

  my @hl = split /\n/, $value;
  foreach my $file_id (@hl) 
  {  if ($file_id =~ /(\d+)\. (.*)MISSING\!/)
     {
       my $block = $1;
        printf "[$block] => \n";
       my  $offset = $blocksize * $block;
        print "xrdfragcp  --frag $offset $blocksize $line \n";
     } 
  } 




}
