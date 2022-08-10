#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';
use File::Basename;

$/ = "\r\n";
my $printPath;
my $help;

GetOptions("printPath" => \$printPath,
           "help|?" => \$help
    ) or printHelp();

if($help) {
  printHelp();
}

sub printHelp
{
  print"gitBaseDir [--printPath] [--help|?]\n";
  print"\tprintPath: print path to git repo, default is to print\n";
  print"\t\trepo base directory name\n";
  print"\thelp: print help\n\n";
  exit 1;
}

my $currentDir = getcwd();

my $topLevel = qx%git rev-parse --show-toplevel 2> /tmp/crap.out %;
if("$topLevel" eq "") {
  print("** NONE **\n");
  exit 1;
}
my $path = dirname($topLevel);
my $topLevel = basename($path);

if($printPath) {
  print("$path\n");
} else {
  print("$topLevel\n");
}
exit 0;
