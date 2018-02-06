#! /usr/bin/env perl

use strict;
use GitModules;
use Cwd;
use File::Basename;

my $pwd = getcwd();
my $base = basename($pwd);
print("\npwd = $pwd; base = $base\n\n");
