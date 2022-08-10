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
    );

if($help) {
  printHelp();
  exit;
}

sub printHelp
{
  print("\nmakeBranch --branchName <name> [--prepend <name>] [--delete <local,remote,both>] [--fetch] [-help|?]\n");
  print("\tThis will make branches in simplorer and bostonvob.\n");
  print("\tthe branchName will be prepended with wschilp unless overridden.\n");
  print("\t--branchName: name of branch\n");
  print("\t--new: create a new branch and push to remote\n");
  print("\t--delete: delete a branch either local, remote or both\n");
  print("\t--prepend: optional prepend\n");
  print("\t--fetch: perform a fetch before doing commands\n\n");
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

if(chdir(".git")) {
  push(@dirs, $pwd);
} else {
  if(chdir("simplorer")) {
    push(@dirs, "simplorer");
    push(@dirs, "bostonvob");
    chdir($pwd);
  } else {
    print("ERROR: not in a git repo and cannot find simplorer\n\n");
    exit 1;
  }
}

my @cmds;
if($fetch) {
  push(@cmds, "echo fetching");
  push(@cmds, "git fetch --progress --all -p");
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
    push(@cmds, "git push origin --delete $branchName");
  }
  if(("$delete" eq "local") || ("$delete" eq "both")) {
    push(@cmds, "git branch -d $branchName");
  }
} else {
  push(@cmds, "git checkout -b ${branchName} --track origin/${branchName}");
}
push(@cmds, "git branch -vv");

for my $dir(@dirs) {
  if(!chdir($dir)) {
    print("ERROR: cannot chdir to $dir\n\n");
    exit 1;
  }
  for my $cmd(@cmds) {
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
  
