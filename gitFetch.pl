#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';
use threads;
use Thread::Queue;

# create a shared queue
my $queue = Thread::Queue->new();
my $endOfQueueMarker = "ENDOFQUEUEMARKER";
my $failedDirsQueue = Thread::Queue->new();
my $pwd = getcwd();

my $pull;
my $all;
my $timeoutTimeSeconds;
my $noXmessage;
my $j;
my $mergeMaster;
my $commitMerge;
my $pushMerge;
my $help;

GetOptions("all" => \$all,
           "pull" => \$pull,
           "timeoutTimeSeconds:i" => \$timeoutTimeSeconds,
           "noxmessage" => \$noXmessage,
           "j:i" => \$j,
           "mergeMaster" => \$mergeMaster,
           "commitMerge" => \$commitMerge,
           "pushMerge" => \$pushMerge,
           "help|?" => \$help,
    );
printHelp() if($help);

my $startTime = time();

my $gitCmd = "fetch";
if($pull) {
  $gitCmd = "pull";
}
if($all) {
  $gitCmd = "$gitCmd --all";
}

if(!defined($timeoutTimeSeconds)) {
  $timeoutTimeSeconds = 0;
}
  
sub printHelp
{
  print("\ngitFetch [--pull] [--all] [-help|?]\n");
  print("\t--pull: performs a pull, git fetch followed by git merge\n");
  print("\ttimeoutTimeSeconds: amount of time in seconds when it will give ");
  print("up, if 0 no timeout\n");
  print("\t--all: fetch/pull all remotes\n");
  print("\t--mergeMaster: merge master into any repo's that are not on");
  print(" master\n");
  print("\t--commitMerge: if there are automerged changes, commit them\n");
  print("\t--pushMerge: if changes are automerged, push them\n");
  print("\t--noxmessage: suppresses xmessage notification\n\n");
  exit;
}

sub update
{
  if(!chdir($pwd)) {
    print("\nERROR: cannot chdir to $pwd\n\n");
    return 1;
  }
  my $error = "0";
  my $done = "0";
  while(!$done) {
    my $dir = $queue->dequeue();
    #print("dir = $dir\n");
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
      print("\nRunning git $gitCmd $here:\n");
      $cmd = "cd $here; pwd; git $gitCmd 2>&1";
      print("running cmd: $cmd\n");
      my @gitRet = qx/$cmd/;
      #print("$cmd return: $?\n");
      chomp(@gitRet);
      foreach my $line(@gitRet) {
        if($line !~ m/igncr/) {
          print("$line\n");
        }
      }
      if($?) {
        print("\n\nERROR: $cmd failed in $here\n\n");
        $failedDirsQueue->enqueue($cmd);
        ++$error;
      } else {
        print("\nUpdate of $here, complete\n");
        print("testing for ${here}/.gitModules\n");
        if(-e "${here}/.gitModules") {
          print("updating $here submodules\n");
          $cmd = "cd ${here}; ~/gitScripts/gitUpdateSubmodules --timeoutTimeSeconds $timeoutTimeSeconds --noxmessage";
          print("running cmd: $cmd\n");
          if(system($cmd)) {
            print("\n\nERROR: $cmd failed\n\n");
            ++$error;
          } else {
            print("\nUpdate of submodules in $here complete\n");
          }
        } else {
          print("did not find ${here}/.gitModules\n");
        }
      }
      if($mergeMaster) {
        $cmd = "cd ${here}; git branch | grep \"^\*\" | awk '{print \$2}'";
        my $branch = qx@$cmd@;
        chomp($branch);
        print("\nbranch = $branch\n");
        if("$branch" ne "master") {
          print("\nNot on master, merging...\n");
          $cmd = "cd ${here}; git fetch";
          if(system($cmd)) {
            print("ERROR: $cmd failed in $here\n");
            return 2;
          }
          $cmd = "cd ${here}; git merge --no-commit origin/master";
          if(system($cmd)) {
            print("ERROR: $cmd failed in $here\n");
            return 3;
          }
          if($commitMerge) {
            my $pushSw = " ";
            if($pushMerge) {
              $pushSw = "--push";
            }
            $cmd = "cd $here; ~/gitScripts/commitAutoMerge $pushSw";
            if(system($cmd)) {
              print("ERROR: commit failed in $here\n");
              return 9;
            }
          }
        } else {
          print("\nOn master\n");
        }
      }
    } else {
      return $error;
    }
  }
}

sub myPrint {
  my $done = "0";
  while(!$done) {
    my $count = $queue->dequeue();
    if((defined($count)) && ($count != "-1")) {
      my $cmd = "xterm -e \"echo crap $count; sleep 3\"";
      system($cmd);
    }
    if($count == "-1") {
      $done = "1";
    }
  }
  return 0;
}

# figure out how many processors
my $numProc = $ENV{NUMBER_OF_PROCESSORS};
if(defined($j) && ($j != 0)) {
  $numProc = $j;
} else {
  if(defined($numProc)) {
    print("$numProc processors detected\n");
  } else {
    print("cannot determine numb of processors, using 4\n");
    $numProc = "4";
  }
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
  $myThreads[$count] = threads->new(\&update);
}

# wait for threads to finish
$| = 1;
my $fail = "0";
my $done = "0";
while(!$done) {
  my $currentTime = time();
  my $deltaTime = $currentTime - $startTime;
  if(($timeoutTimeSeconds > 0) && ($deltaTime > $timeoutTimeSeconds)) {
    print("\nERROR: fetch timed out at $deltaTime seconds\n\n");
    # detach all threads so we can terminate
    for(my $count = 0; (($count < $numProc) && 
                        ($count < $numRepos)); ++$count) {
      $myThreads[$count]->detach();
    }
    $fail = "1";
    $done = "1";
  } else {
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
    print("$numReposLeft ");
  }
}
# reap all the myThreads unless we already timed out
if(!$fail) {
  for(my $count = 0; (($count < $numProc) && 
                      ($count < $numRepos)); ++$count) {
    my $ret = $myThreads[$count]->join();
    if($ret) {
      print("\n\nERROR: update failed\n\n");
      $fail = "1";
    }
  }
}
if(!$noXmessage && (-f "/usr/bin/xmessage")) {
  my $output;
  if(!$fail) {
    $output = "SUCCESS: ";
  } else {
    $output = "FAILED: ";
  }
  my $cmd = "xmessage -center \"${output}git update in $pwd\"";
  system($cmd);
}
if(!$fail) {
  print("\n\nUpdate completed successfully\n\n");
  exit 0;
} else {
  print("\n\nUpdate FAILED\n\n");
  print("Failed commands:\n");
  my $errDone = "0";
  while(!$errDone) {
    if(defined(my $err = $failedDirsQueue->dequeue_nb())) {
      print("\t$err\n");
    } else {
      $errDone = "1";
    }
  }
  exit 1;
}
