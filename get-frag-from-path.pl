#!/usr/bin/perl

use strict;
use warnings;

my ($line, $server) = @ARGV;

if (not defined $line) {
  die "Need path\n";
}


if (not defined $server) {
  die "Need server\n";
}

chomp $line;
$line=~s/\s+$//;

# fragcp output prefix, this should go to /dev/null in future
my $prefix="frag";
if ($line =~ /(.*)\/(.*)\.root$/) {
    $prefix = "frag_$2"
}

my $fsckc = "hdfs fsck  -locations -blocks -files /cms/phedex$line";
# print "$fsckc \n";
my $value = `$fsckc` ;
# print $value;
if ($value =~ /HEALTHY/) { printf ("HEALTHY $line!\n"); exit 0; }; 

my @hl = split /\n/, $value;

foreach my $file_id (@hl) 
{  
    printf(" >> $file_id \n");
    if ($file_id =~ /(\d+)\. (.*)MISSING\!/)
    {
        my $block = $1;
        printf "MISSING [$block] \n";
        my $blocksize = 1024*1024*128;
        my $offset = $blocksize * $block;
        my $cmd = "./xrdfragcp --prefix $prefix --frag $offset $blocksize root://$server/$line?tried=xrootd.t2.ucsd.edu \n";
        print "$cmd \n";
        exec("time $cmd");
    }
}

