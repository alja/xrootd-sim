#!/usr/bin/perl

use strict;
use Getopt::Long;
use File::Basename;
use POSIX qw(WNOHANG);

if (@ARGV < 2) {
  print STDERR "Usage: ./heal-parallel-dir.pl  --dir=/cms/phedex/store/mc,/cms/phedex/store/data  --N_max=8  --server=xrd-cache-1.t2.ucsd.edu:2020\n";
    exit 1;
}


my $N_max = 3;
my $N = 0;
my %pmap;
my $current_line = 0;


# configurable
my $dir    = "";
my $server  = "";
my $jobs   = 0;
my $verbose = "";

my $result = GetOptions ( "dir=s"    => \$dir,
                          "server=s"  => \$server,
                          "jobs=i"    => \$jobs,
                          "N_max=i"   => \$N_max,
                          "verbose"   => \$verbose);

my @array;
my $value;
my @dira =  split /\,/, $dir;
foreach my $dd (@dira)
{
    $value .= `hdfs fsck $dd` ;
}
print ($value);
my @hl = split /\n/, $value;
foreach my $fsck_line (@hl) 
{
    if ($fsck_line =~ /cms\/phedex(.*).root: MISSING/)
    {
        push( @array, "$1.root");
    }
}

if (!$jobs)
{
  printf("Warning njobs not defined \n");
  $jobs = @array;
}


my $current_line = 0;
my $last_line = $current_line + $jobs;
if ( $last_line > @array ) {
  $last_line = @array;
}
print "currentline = $current_line, lastline = $last_line \n";

foreach (@array) {
  print "$_\n";
}



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
    open XXX, ">log/dump.$current_line";
    open STDOUT, ">&XXX";
    open STDERR, ">&XXX";
    }

    my $line =$array[$current_line]; 
    chomp $line;
    my $pcmd = "./get-frag-from-path.pl $line $server";
    print("run_child() $pcmd\n");
    exec($pcmd);
  }
}



################################################################################

sub make_new_children
{
  while ($N < $N_max && $current_line < $last_line)
  {
    run_child();
    print("run child $N (line $current_line)\n");
  }
}

################################################################################
# main
################################################################################


$SIG{CHLD} = &sig_child_handler;

while ( $current_line < $last_line )
{
  make_new_children();
  sleep 5; # will get interrupted on signal!
  reap_children();
}

while (%pmap)
{
  my $size = keys %pmap;
  print "Waiting on $size processes to finish ...\n";
  foreach(keys %pmap) { print "$_ / $pmap{$_}\n"; }
  sleep 10;
  reap_children();
}
