#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';


my $branchName;
my $help;
my $prepend;
my $new;
my $delete;
my $fetch;

GetOptions("branchName=s" => \$branchName,
           "prepend=s" => \$prepend,
           "new" => \$new,
           "delete=s" => \$delete,
           "fetch" => \$fetch,
           "help|?" => \$help,
    ) or printHelp();

if($help) {
  printHelp();
}

sub printHelp
{
  print("\nmakeBranch --branchName <name> [--prepend <name>] [--delete <local,remote,both>] [--fetch] [-help|?]\n");
  print("\tThis will make branches in all repo's.\n");
  print("\tthe branchName will be prepended with wschilp unless overridden.\n");
  print("\t--branchName: name of branch\n");
  print("\t--new: create a new branch and push to remote\n");
  print("\t--delete: delete a branch either local, remote or both\n");
  print("\t--prepend: optional prepend\n");
  print("\t--fetch: perform a fetch before doing commands\n\n");
  exit 1;
}

if(!$branchName) {
  print("ERROR: must provide a branchName\n\n");
  printHelp();
  exit 1;
}
if(!$prepend) {
  if($branchName =~ /^wschilp/) {
    $prepend = "";
  } else {
    $prepend = "wschilp_";
  }
}

$branchName = "${prepend}${branchName}";

my $pwd = getcwd();
my @dirs;

# find all repo's
my $numRepos = "0";
if(chdir(".git")) {
  chdir($pwd);
  push(@dirs, $pwd);
  ++$numRepos;
} else {
  my @ls = qx/ls -1/;
  chomp(@ls);
  foreach my $dir(@ls) {
    if(chdir("${dir}/.git")) {
      if(($dir eq "bostonvob")) {
        print("skipping $dir\n");
      } else {
        push(@dirs, $dir);
        ++$numRepos;
      }
      chdir($pwd);
    }
  }
}
print("numRepos = $numRepos\n");
if($numRepos eq "0") {
  print("No repositories found in $pwd\n\n");
  exit 2;
}

for my $dir(@dirs) {
  if(!chdir($dir)) {
    print("ERROR: cannot chdir to $dir\n\n");
    exit 1;
  }
  my @cmds;
  if($fetch) {
    push(@cmds, "echo fetching");
    push(@cmds, "git fetch --progress -p");
  }
  if($new) {
    push(@cmds, "git checkout -b ${branchName}");
    push(@cmds, "git push origin $branchName");
    push(@cmds, "git branch --set-upstream-to origin/$branchName");
  } elsif($delete) {
    my $list = qx/git branch --list $branchName/;
    if($list =~ m/\*/) {
      push(@cmds, "git checkout master");
    }
    if(("$delete" eq "remote") || ("$delete" eq "both")) {
      if(($dir eq "simplorer") || ($dir eq "bostonvob")) {
        push(@cmds, "git push origin --delete $branchName");
      }
    }
    if(("$delete" eq "local") || ("$delete" eq "both")) {
      push(@cmds, "git branch -d $branchName");
    }
  } else {
    push(@cmds, "git checkout -b ${branchName} --track origin/${branchName}");
  }
  push(@cmds, "git branch -vv");
  for my $cmd(@cmds) {
    print("Running cmd: $cmd\n");
    my @gitRet = qx/$cmd/;
    #print("$cmd return: $?\n");
    chomp(@gitRet);
    foreach my $line(@gitRet) {
      if($line !~ m/igncr/) {
        print("$line\n");
      }
    }
    if($?) {
      print("\n\nERROR: $cmd failed in $dir\n\n");
      exit 2;
    }
  }
  chdir($pwd);
}
print("\n\nSuccess!!\n\n");
  
