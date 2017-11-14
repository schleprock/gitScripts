#! /usr/bin/env perl

use strict;
use GitModules;
use Cwd;

my $dir = "/cygdrive/d/ansysdev/git/vs15debug/Ansys_CDU_nosync";
my $branch = "xhao_new_mono_3.12_r1";
my $cmd = "cd $dir; git branch -r";
my $output = qx/$cmd/;
chomp($output);
print("\noutput = $output\n");
if($output =~ /origin\/${branch}$/m) {
  print("found it\n");
} else {
  print("not found\n");
}
