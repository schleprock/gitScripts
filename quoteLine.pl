#! /usr/bin/env perl

use strict;
$/ = "\r\n";

my $input;
while ($input = <STDIN>) {
  chomp($input);
  my @lines = split(/\n/, $input);
  foreach my $line(@lines) {
    $line = "\"$line\"";
    print("$line\n");
  }
}
