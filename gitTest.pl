#! /usr/bin/env perl

use strict;
use GitModules;
use Cwd;
use File::Basename;
use Term::ANSIColor;

my $pwd = getcwd();
my $base = basename($pwd);
print color 'bold';
print("\npwd = $pwd; base = $base\n\n");
