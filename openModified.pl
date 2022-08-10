#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';

my $cmd = "gitStatus.pl | grep modified | awk '{print \$3}' | xargs /cygdrive/d/emacs-24.3/bin/runemacs.exe";
system($cmd);
