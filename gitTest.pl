#! /usr/bin/env perl

use strict;
use GitModules;
use Cwd;

sub myRoutine {
  my $pwd = getcwd();
  print("\nFoo in $pwd\n");
  return(0);
}

my $fail = GitModules::runCmd(\&myRoutine, 0, 1, 0);
if(!$fail) {
  print("\n\ngit runCmd completed successfully\n\n");
} else {
  print("\n\ngit runCmd FAILED\n\n");
}
