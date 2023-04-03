package GitModules;

use strict;
use Cwd;
use Cwd 'chdir';
use threads;
use Thread::Queue;
use File::Basename;
use Time::HiRes qw(usleep);

my $endOfQueueMarker = "ENDOFQUEUEMARKER";

sub test {
  print("Testing testing testing\n\n");
}

sub numbProcessors {
  # parameters (j, debugmode)
  # figure out how many processors
  my $j = $_[0];
  my $debugMode = $_[1];
  
  my $numProc;
  if(defined($j) && ($j != 0)) {
    $numProc = $j;
  } else {
    $numProc = $ENV{NUMBER_OF_PROCESSORS};
    if(defined($numProc)) {
      if($debugMode) {
        print("$numProc processors detected\n");
      }
    } else {
      print("cannot determine numb of processors, using 4\n");
      $numProc = "4";
    }
  }
  return($numProc);
}

sub findAllRepos {
  # the first parameter will be the function used to push a repo dir onto
  # a list, or queue or whatever of repo's.
  my $addRepoFunc = $_[0];
  my $pwd = $_[1];
  my $debugMode = $_[2];
  if(! defined $_[2]) {
    print("\nERROR: not enough parameters to findAllRepos, needs to be 3\n");
    exit 9;
  }
  my $numRepos = 0;
  if(chdir(".git")) {
    chdir($pwd);
    $addRepoFunc->(".");
    ++$numRepos;
  } else {
    my @ls = qx/ls -1/;
    chomp(@ls);
    foreach my $dir(@ls) {
      if(chdir("${dir}/.git")) {
        $addRepoFunc->($dir);
        ++$numRepos;
        chdir($pwd);
      }
    }
  }
  if($debugMode) {
    print("numRepos = $numRepos\n");
  }
  if($numRepos eq "0") {
    print("No repositories found in $pwd\n\n");
    exit 2;
  }
  return($numRepos);
}

sub runThread {
  # parameters (dequeueSubroutine, subroutineToRun, baseDirectory, debugMode)
  my $dequeue = $_[0];
  my $subroutineToRun = $_[1];
  my $baseDir = $_[2];
  my $debugMode = $_[3];

  if(!defined($debugMode)) {
    $debugMode = 0;
  }
  if(!chdir($baseDir)) {
    print("\nERROR: cannot chdir to $baseDir\n");
    return(1);
  }
  my $error = "0";
  my $done = "0";
  while(!$done) {
    my $dir = $dequeue->();
    if($debugMode) {
      print("dir = $dir\n");
    }
    if(defined($dir) && ($dir ne $endOfQueueMarker)) {
      my $cmd;
      my $here = "${baseDir}/${dir}";
      if($dir eq ".") {
        $here = $baseDir;
      }
      if(!-d($here)) {
        print("ERROR: $here is not a directory\n");
        return 1;
      }
      if($debugMode) {
        print("\nRunning: here: $here:\n");
      }
      if(!chdir($here)) {
        print("ERROR cannot chdir to $here\n\n");
        ++$error;
      } else {
        if($subroutineToRun->($here)) {
          print("\n\nERROR: subroutineToRun failed in $here\n\n");
          ++$error;
        } elsif($debugMode){
          print("\nCommand at $here, complete\n");
        }
      } 
    } else {
      return $error;
    }
  }

}

sub runCmd {
  # parameters (subroutineToRun, numProc, debugMode)
  my $subroutineToRun = $_[0];
  my $j = $_[1];
  my $debugMode = $_[2];

  if(!defined($subroutineToRun)) {
    print("\nERROR: invalid subroutineToRun to runCmd subroutine\n\n");
    exit 1;
  }
  if(!defined($debugMode))
  {
    $debugMode = 0;
  }
  # create a shared queue
  my $queue = Thread::Queue->new();
  my $pwd = getcwd();

  # find all repo's
  my $numRepos = GitModules::findAllRepos(sub{$queue->enqueue(@_)}, $pwd,
      $debugMode);
  if($debugMode) {
    print("found $numRepos repos\n");
  }
  for(my $count = 0; $count < $numRepos; ++$count) {
    $queue->enqueue($endOfQueueMarker);
  }

  my $numProc = GitModules::numbProcessors($j, $debugMode);

  # create a thread per cpu up to numProc or numb of repos
  my @myThreads;
  for(my $count = "0"; (($count < $numProc) &&
                        ($count < $numRepos)); ++$count) {
    if($debugMode) {
      print("Creating queue $count\n");
    }
    $myThreads[$count] = threads->
        new(sub{runThread(sub{return($queue->dequeue())},
                          $subroutineToRun,
                          $pwd)});
    usleep(100000);
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
    if(($numProc > 1) && $debugMode) {
      print("$numReposLeft ");
    }
  }

  # reap all the myThreads
  my $fail = "0";
  for(my $count = 0; (($count < $numProc) && 
                      ($count < $numRepos)); ++$count) {
    my $ret = $myThreads[$count]->join();
    if($ret) {
      if($debugMode) {
        print("\nERROR: thread $count failed\n");
      }
      $fail = "1";
    }
  }
  return($fail);
}

# returns empty string if not in a repo
sub gitRepoName
{
  my $here = $_[0];
  if(!chdir($here)) {
    print("\nERROR: cannot chdir to $here\n\n");
    return;
  }
  # retrieve repo name
  my $basePath = qx!cd $here; git rev-parse --show-toplevel 2>/dev/null!;
  chomp($basePath);
  if(! length $basePath) {
    return;
  }
  my $repo = basename($basePath);
  chomp($repo);
  return($repo);
}

1;
