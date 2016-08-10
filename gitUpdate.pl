#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';

my $noxmessage;
my $noMergeMaster;
my $commitMerge;
my $pushMerge;
my $j;
my $help;

GetOptions("noxmessage" => \$noxmessage,
           "noMergeMaster" => \$noMergeMaster,
           "commitMerge" => \$commitMerge,
           "pushMerge" => \$pushMerge,
           "j:i" => \$j,
           "help|?" => \$help,
    );

if($help) {
  printHelp();
}

sub printHelp
{
  print("gitUpdate [--noxmessage] [--noMergeMaster] [--j <int>] ");
  print("[--commitMerge] \n\t\t[--pushMerge] [--help]\n");
  print("Update a set of repo's or just a single repo. Default is to\n");
  print("automerge any non-master branches with master unless this script\n");
  print("is run in a single repo (like simplorer).\n");
  print("\t--noxmessage: suppress xmessage\n");
  print("\t--noMergeMaster: if a branch is not on master, don't merge. ");
  print("Default \n\t\tis to merge master into branch\n");
  print("\t--commitMerge: if there are automerged changes, commit them\n");
  print("\t--pushMerge: if changes are automerged, push them.\n");
  print("\t--j <int>: set parallel limit, default is all cpu's\n");
  print("\t--help: print help\n");
  exit 0;
}

my $pwd = cwd();
my $fail = 0;
my $output;


my $pushMergeSw = " ";
if($pushMerge) {
  $pushMergeSw = "--pushMerge";
}
my $commitMergeSw = " ";
if($commitMerge) {
  $commitMergeSw = "--commitMerge";
} else {
  $pushMergeSw = " ";
}
my $mergeMasterSw = "--mergeMaster";
if($noMergeMaster) {
  $mergeMasterSw = " ";
  $commitMergeSw = " ";
  $pushMergeSw = " ";
}
if(-d ".git") {
  # don't merge if we're in a repo, only merge if above
  $mergeMasterSw = " ";
  $commitMergeSw = " ";
  $pushMergeSw = " ";
}

my $jSw = " ";
if(defined($j) && ($j != 0)) {
  $jSw = "-j $j";
}

my $cmd = "~/gitScripts/gitFetch.pl --pull --all --noxmessage";
$cmd = "$cmd $mergeMasterSw $commitMergeSw $pushMergeSw $jSw";
my $res = system($cmd);
print("\n$cmd returned $res\n");
if($res)
{
  $fail = 1;
  $output = "Update FAILED: $cmd failed in $pwd";
  printAndExit();
}

if(chdir(".git")) {
  # we're in a git repo, don't run the 3rdparty stuff
  $output = "Update SUCCEEDED in $pwd";
  printAndExit();
}

$cmd = "~/gitScripts/3rdpartyArtifactory";
$res = system($cmd);
print("\n$cmd returned $res\n");
if($res)
{
  $output = "Update FAILED: $cmd failed in $pwd";
  $fail = 1;
  printAndExit();
}
$output = "Update SUCCEEDED in $pwd";
printAndExit();



sub printAndExit
{
  print("\n$output\n\n");
  if(!$noxmessage && (-f "/usr/bin/xmessage")) 
  {
    my $cmd = "xmessage -center \"${output}\"";
    system($cmd);
  }
  exit($fail);
}
