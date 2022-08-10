package TestModule;

use strict;
use Cwd;
use Cwd 'chdir';

sub populateQueue {
  my $enqueue = $_[0];

  $enqueue->("foo");
}


1;
