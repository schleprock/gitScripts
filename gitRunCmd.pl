#! /usr/bin/env perl

use strict;

use GitModules;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';
use threads;
use Thread::Queue;

my $command;
my $j;
my $help;
my $noXmessage = 0;
my $debugMode;

GetOptions("command=s" => \$command, #command to run
           "j:i" => \$j, #run commands in parallel
           "noxmessage" => \$noXmessage, #disable xmessage
           "debugMode" => \$debugMode, 
           "help|?" => \$help,
    ) or printHelp();

printHelp() if($help);

sub printHelp {
  print("\ngitRunCmd --command <cmd> [--j [numb]][--help|?]\n");
  print("\t--j [numb]: run commands in parallel\n");
  print("\t--command: command to run in each directory\n");
  print("\t--noxmessage: suppress xmessage\n");
  print("\t--debugMode: turn on debugMode (off by default)\n");
  print("\n\n");
  exit;
}

my $pwd = getcwd();

my $failures = Thread::Queue->new();

sub runCmd {
  my $here = $_[0];
  if(!chdir($here)) {
    my $err = "\nERROR: cannot chdir to $here\n";
    print("$err");
    $failures->enqueue($err);
    return(1);
  }
  print("\nRunning: $command here: $here:\n");
  if(system("cd $here; $command")) {
    my $err = "\nERROR: $command failed in $here\n";
    print("$err");
    $failures->enqueue($err);
    return(1);
  } else {
    print("\nCommand at $here, complete\n");
    return(0);
  }
}

my $fail = GitModules::runCmd(\&runCmd, $j, $debugMode);

if(!$noXmessage && (-f "/usr/bin/xmessage")) {
  my $output;
  if(!$fail) {
    $output = "SUCCESS: ";
  } else {
    $output = "FAILED: ";
  }
  my $cmd = "xmessage -center \"${output}git runCmd in $pwd\"";
  system($cmd);
}
if(!$fail) {
  print("\n\ngit runCmd completed successfully\n\n");
  exit(0);
}
print("\n\ngit runCmd FAILED\n\n");
my $errDone = "0";
while(!$errDone) {
  if(defined(my $err = $failures->dequeue_nb())) {
    print("\n$err\n");
  } else {
    $errDone = "1";
  }
}
exit(1);
