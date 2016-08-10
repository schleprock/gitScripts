#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';

my $noxmessage;
my $noMergeMaster;
my $j;

GetOptions("noxmessage" => \$noxmessage,
           "noMergeMaster" => \$noMergeMaster,
           "j:i" => \$j,
    );


my $pwd = cwd();
my $fail = 0;
my $output;

my $mergeMasterSw = "--mergeMaster";
if($noMergeMaster) {
  $mergeMasterSw = " ";
}
if(-d ".git") {
  # don't merge if we're in a repo, only merge if above
  $mergeMasterSw = " ";
}

my $jSw = " ";
if(defined($j) && ($j != 0)) {
  $jSw = "-j $j";
}

my $cmd = "~/gitScripts/gitFetch.pl --pull --all --noxmessage";
$cmd = "$cmd $mergeMasterSw $jSw";
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
