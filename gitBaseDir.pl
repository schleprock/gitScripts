#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';
use File::Basename;

$/ = "\r\n";

my $currentDir = getcwd();

my $topLevel = qx%git rev-parse --show-toplevel 2> /tmp/crap.out %;
if("$topLevel" eq "") {
  print("** NONE **\n");
  exit 1;
}
my $path = dirname($topLevel);
my $topLevel = basename($path);

print("$topLevel");
exit 0;
