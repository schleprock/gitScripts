#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';
use threads;
use Thread::Queue;

$| = 1; # set autoflush

# create a shared queue
my $queue = Thread::Queue->new();
my $endOfQueueMarker = "ENDOFQUEUEMARKER";
my $errors = Thread::Queue->new();
my $pwd = getcwd();
print("pwd = $pwd\n");

my $help;
my $cleanLinks;

GetOptions("cleanLinks" => \$cleanLinks,
           "help|?" => \$help,
    ) or printHelp();

printHelp() if($help);

sub printHelp
{
  print("\ngitClean [--cleanlinks ] [-help|?]\n");
  print("\t--cleanLinks: delete old symlinks\n");
  exit 1;
}

sub clean {
  my $threadNumb = shift;
  my $done = "0";
  while(!$done) {
    my $dir = $queue->dequeue();
    print("\nThread $threadNumb dequeued $dir\n");
    if(defined($dir) && ($dir ne $endOfQueueMarker)) {
      my $cmd;
      my $here = "${dir}";
      if($dir eq ".") {
        $here = $pwd;
      }
      if(!-d($here)) {
        print("ERROR: $here is not a directory\n");
        $errors->enqueue("ERROR: $here is not a directory");
        return 1;
      }
      print("\nCleaning $here:\n");
      print("\nDeleting ${here}/.gitignore-local\n");
      my $cmd = "rm -f ${here}/.gitignore-local";
      qx/$cmd/;
      print("\n$cmd complete in thread $threadNumb\n");
      if($cleanLinks) {
        print("\nDeleting $here symlinks\n");
        my @links = qx\find $here -type l\;
        chomp(@links);
        foreach my $link(@links) {
          $cmd = "rm -f \"$link\"";
          system($cmd);
        }
      }
      print("\nRunning git clean in $here\n");
      $cmd = "cd $here; git clean -fxd -f";
      print("\n...running $cmd in thread $threadNumb\n");
      if(system($cmd)) {
        print("\n\nERROR: git clean failed in $here\n\n");
        $errors->enqueue("ERROR: git clean failed in $here");
        return 1;
      }
      print("\ngit clean of $here complete\n");
    } else {
      $done = 1;
    }
  }
  print("\nThread $threadNumb is done\n\n");
  return 0;
}


# figure out how many processors
my $numProc = $ENV{NUMBER_OF_PROCESSORS};
if(defined($numProc)) {
  print("$numProc processors detected\n");
} else {
  print("cannot determine numb of processors, using 4\n");
  $numProc = "4";
}
if($numProc > "16") {
  print("restricting numProc to 16\n");
  $numProc = "16";
}
#$numProc = "1";

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
    if(chdir("${pwd}/${dir}/.git")) {
      $queue->enqueue("${pwd}/${dir}");
      ++$numRepos;
      chdir($pwd);
    }
  }
}
print("numRepos = $numRepos\n");

for(my $count = 0; $count < $numRepos; ++$count) {
  $queue->enqueue($endOfQueueMarker);
}

# create a thread per cpu up to numProc or numb of repos
my @myThreads;
for(my $count = "0"; (($count < $numProc) &&
                      ($count < $numRepos)); ++$count) {
  print("Creating queue $count\n");
  $myThreads[$count] = threads->create(\&clean, $count);
}

# wait for threads to finish
my $done = "0";
while(!$done) {
  $done = "1";
  sleep("1");
  my $remaining = 0;
  for(my $count = 0; (($count < $numProc) && 
                      ($count < $numRepos)); ++$count) {
    if(!$myThreads[$count]->is_joinable()) {
      ++$remaining;
      # print("\nThread $count is not joinable\n");
      $done = "0";
    }
  }
  #print(" $remaining");
}
# reap all the myThreads
my $fail = "0";
for(my $count = 0; (($count < $numProc) && 
                    ($count < $numRepos)); ++$count) {
  my $ret = $myThreads[$count]->join();
  if($ret) {
    print("\nERROR: clean failed\n\n");
    $fail = "1";
  }
}
my $cmd = "rm -rf build_output";
system($cmd);
if(!$fail) {
  print("\n\ngit Clean completed successfully\n\n");
} else {
  my $errDone = "0";
  while(!$errDone) {
    if(defined(my $err = $errors->dequeue_nb())) {
      print("\n$err\n");
    } else {
      $errDone = "1";
    }
  }
  print("\n\ngit Clean FAILED\n\n");
}
