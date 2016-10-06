#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';

my $help;
my $untracked;
my $ignored;
my $all;

GetOptions("untracked" => \$untracked, #show untracked files/dirs
           "ignored" => \$ignored, #show ignored files/dirs
           "all" => \$all, #show untracked, ignored files/dirs
           "help|?" => \$help,
    ) or printHelp();

printHelp() if($help);

sub printHelp
{
  print("\ngitStatus [--untracked] [--ignored] [--all] [-help|?]\n");
  print("\t--untracked: show untracked files\n");
  print("\t--ignored: show ignored files\n");
  print("\t--all: show untracked and ignored files/dirs\n");
  exit 1;
}

my $pwd = getcwd();
my @dirs;
if(chdir(".git")) {
  chdir($pwd);
  push(@dirs,".");
} else {
  my @ls = qx/ls -1/;
  chomp(@ls);
  foreach my $dir(@ls) {
    if(chdir("${dir}/.git")) {
      push(@dirs, $dir);
      chdir($pwd);
    }
  }
}
my $arg = "-uno";
if($all || $untracked) {
  $arg = "-unormal";
}
if($all || $ignored) {
  $arg = "$arg --ignored";
}
my $cmd = "git status $arg";
print("running $cmd\n\n");
foreach my $dir(@dirs) {
  chdir($dir);
  my $here = getcwd();
  print("Status for $here:\n");
  system($cmd);
  print("\n\n");
  chdir($pwd);
}
