#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';

my $command;
my $parallel;
my $help;
my $noXmessage = 0;

use threads;
use Thread::Queue;

# create a shared queue
my $queue = Thread::Queue->new();
my $endOfQueueMarker = "ENDOFQUEUEMARKER";

GetOptions("command=s" => \$command, #command to run
           "parallel:i" => \$parallel, #run commands in parallel
           "noxmessage" => \$noXmessage, #disable xmessage
           "help|?" => \$help,
    ) or printHelp();

printHelp() if($help);

sub printHelp {
  print("\ngitRunCmd --command <cmd> [--parallel [numb]][--help|?]\n");
  print("\t--parallel [numb]: run commands in parallel\n");
  print("\t--command: command to run in each directory\n\n");
  exit;
}

my $pwd = getcwd();
my @dirs;
if(chdir(".git")) {
  chdir($pwd);
  push(@dirs,".");
} else {
  my @ls = qx/ls -1/;
  chomp(@ls);
  foreach my $dir(@ls) {
    if(chdir("${dir}/.git")) {
      push(@dirs, $dir);
      chdir($pwd);
    }
  }
}

# figure out how many processors
my $numProc;
if(defined($parallel)) {
  if($parallel == 0) {
    $numProc = $ENV{NUMBER_OF_PROCESSORS};
    if(defined($numProc)) {
      print("$numProc processors detected\n");
    } else {
      print("cannot determine numb of processors, using 4\n");
      $numProc = "4";
    }
  } else {
    $numProc = $parallel;
  }
}
if((!defined($numProc)) || ($numProc == 0)) {
  $numProc = 1;
}

# find all repo's
my $numRepos = "0";
if(chdir(".git")) {
  chdir($pwd);
  $queue->enqueue(".");
  ++$numRepos;
} else {
  my @ls = qx/ls -1/;
  chomp(@ls);
  foreach my $dir(@ls) {
    if(chdir("${dir}/.git")) {
      $queue->enqueue("$dir");
      ++$numRepos;
      chdir($pwd);
    }
  }
}
print("numRepos = $numRepos\n");
if($numRepos eq "0") {
  print("No repositories found in $pwd\n\n");
  exit 2;
}

for(my $count = 0; $count < $numRepos; ++$count) {
    $queue->enqueue($endOfQueueMarker);
}

# create a thread per cpu up to numProc or numb of repos
my @myThreads;
for(my $count = "0"; (($count < $numProc) &&
                      ($count < $numRepos)); ++$count) {
  print("Creating queue $count\n");
  $myThreads[$count] = threads->new(\&runCmd);
}

# wait for threads to finish
$| = 1;
my $done = "0";
while(!$done) {
  my $numReposLeft = "0";
  $done = "1";
  sleep("1");
  for(my $count = 0; (($count < $numProc) && 
                      ($count < $numRepos)); ++$count) {
    if(!$myThreads[$count]->is_joinable()) {
      ++$numReposLeft;
      $done = "0";
    }
  }
  if($numProc > 1) {
    print("$numReposLeft ");
  }
}

# reap all the myThreads

my $fail = "0";
for(my $count = 0; (($count < $numProc) && 
                    ($count < $numRepos)); ++$count) {
  my $ret = $myThreads[$count]->join();
  if($ret) {
    print("\nERROR: rebase failed\n\n");
    $fail = "1";
  }
}
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
} else {
  print("\n\ngit runCmd FAILED\n\n");
}

sub runCmd {
  if(!chdir($pwd)) {
    print("\nERROR: cannot chdir to $pwd\n\n");
    return 1;
  }
  my $error = "0";
  my $done = "0";
  while(!$done) {
    my $dir = $queue->dequeue();
    print("dir = $dir\n");
    if(defined($dir) && ($dir ne $endOfQueueMarker)) {
      my $cmd;
      my $here = "${pwd}/${dir}";
      if($dir eq ".") {
        $here = $pwd;
      }
      if(!-d($here)) {
        print("ERROR: $here is not a directory\n");
        return 1;
      }
      print("\nRunning: $command here: $here:\n");
      if(!chdir($here)) {
        print("ERROR cannot chdir to $here\n\n");
        ++$error;
      } else {
        if($numProc > 1) {
          $cmd = "xterm.exe -e \"$command; sleep 2\"";
        } else {
          $cmd = $command;
        }
        if(system("$cmd")) {
          print("\n\nERROR: $cmd failed in $here\n\n");
          ++$error;
        } else {
          print("\nCommand at $here, complete\n");
        }
      } 
    } else {
      return $error;
    }
  }
}
