#!/usr/bin/perl

use strict;
use Getopt::Long;
use File::Basename;
use POSIX qw(WNOHANG);

if (@ARGV < 2) {
  print STDERR "Usage: ./heal-parallel.pl --mode=1 --file=all_files.txt  --jobs=3 --jobsOff=12 --server=xrd-cache-1.t2.ucsd.edu:2020\n";
    exit 1;
}


my $N_max = 64;
my $N = 0;
my %pmap;
my $current_line = 0;


# configurable
my $file    = "";
my $server  = "";
my $jobs   = 0;
my $jobsOff   = 0;
my $verbose = "";
my $mode = 0;


my $result = GetOptions ( "file=s"    => \$file,
                          "server=s"  => \$server,
                          "jobs=i"    => \$jobs,
                          "jobsOff=i" => \$jobsOff,
                          "mode=i"   => \$mode,
                          "verbose"   => \$verbose);

printf "list offset $jobsOff\n";
open(INFO, $file) or die("Could not open file $file.");
open FILE, "<$file" or die "Could not open $file: $!\n";
my @array=<FILE>;

if (!$jobs)
{
  printf("Warning njobs not defined \n");
  exit;
#  $jobs = @array;
}

$current_line = $jobsOff;
my $last_line = $current_line + $jobs;
if ( $last_line > @array ) {
  $last_line = @array;
}
print "currentline = $current_line, lastline = $last_line \n";



close FILE;

################################################################################
# Signal handler
################################################################################

sub sig_child_handler
{
  my $sig = shift;

  print "Sig$sig received, N = $N.\n";
}

sub reap_children
{
  while ((my $kid = waitpid(-1, POSIX::WNOHANG)) > 0)
  {
    my $status = $? >> 8;
    print "Reaped child with PID $kid, line_num = $pmap{$kid}, status $status.\n";

    # print "Output follows:\n";
    # system "cat dump.$pmap{$kid}";

    delete $pmap{$kid};
 
    --$N;
  }
}

################################################################################

sub run_child
{
  my $pid = fork();

  ++$current_line;

  if ($pid < 0)
  {
    --$current_line;
    print "  Failed: $pid $!\n";

    # If it's a resource problem, could also do sleep + return
    exit 1;
  }
  if ($pid)
  {
    $pmap{$pid} = $current_line;
    ++$N;
  }
  else {
    my $redirect = 1;
    if ($redirect) {
    close STDIN;
    close STDOUT;
    close STDERR;
    open XXX, ">dump.$current_line";
    open STDOUT, ">&XXX";
    open STDERR, ">&XXX";
    }
    
    # URL
    my $line =$array[$current_line];
    if ( $mode)
    {
      my $p = $array[$current_line]; chomp $p;
       print("ffff____ $p _____4444\n");

       exec("xrdcp -f root://$server/$p /dev/null");
    }
    else
    {
       exec("./heal-path.pl $array[$current_line] $server");
    }
      
   }
}




################################################################################

sub make_new_children
{
  while ($N < $N_max && $current_line < $last_line)
  {
    run_child();
    print("run child $current_line\n");
  }
}

################################################################################
# main
################################################################################


$SIG{CHLD} = &sig_child_handler;

while ( $current_line < $last_line )
{
  make_new_children();
  sleep 100; # will get interrupted on signal!
  reap_children();
}

while (%pmap)
{
  my $size = keys %pmap;
  print "Waiting on $size processes to finish ...\n";
  sleep 10;
  reap_children();
}
