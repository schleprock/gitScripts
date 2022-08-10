#! /usr/bin/env perl

use strict;
use GitModules;
use Cwd;
use File::Basename;
use Term::ANSIColor;

my $basePath = qx!git rev-parse --show-toplevel 2>/dev/null!;
chomp($basePath);
my $base = "not in git repo";
if(! length $basePath) {
  print("not in git repo");
}
print color 'bold';
print("\nbasePath = $basePath; base = $base\n\n");
