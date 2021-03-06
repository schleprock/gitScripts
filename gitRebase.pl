#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';

my $remotePath;
my $rebase;
my $nopull;
my $help;

GetOptions("path=s" => \$remotePath, 
           "rebase" => \$rebase, #rebase to master
           "nopull" => \$nopull, #don't do a fetch/pull
           "help|?" => \$help,
    ) or printHelp();

printHelp() if($help);

sub printHelp {
  print("\ngitRebase [--rebase] [--help|?]\n");
  exit 1;
}

if(!$remotePath) {
    $remotePath = "w:/ansysdev/git/pittstashClone";
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
foreach my $dir(@dirs) {
  my $cmd;
  chdir($dir);
  my $cwd = getcwd();
  my $repo = $dir;
  if("$repo" eq ".") {
    $repo = $cwd;
    $repo =~ s/^.*\///;
  }
  if($rebase) {
    print("current remote:\n");
    system("git remote -v");
    $cmd = "git remote rm origin";
    print("running $cmd in $cwd\n");
    system($cmd);
    print("current remote:\n");
    system("git remote -v");
    $cmd = "git remote add origin \"${remotePath}/${repo}\"";
    print("running $cmd in $cwd\n");
    system($cmd);
    print("current remote:\n");
    system("git remote -v");
  }
  if(! $nopull) {
    my @cmds = ("git fetch --progress",
                "git branch --set-upstream-to=origin/master master",
                # "git checkout --force -B \"master\" \"origin/master\"",
                "git pull");
    foreach $cmd(@cmds) {
      print("running $cmd in $repo (ignore igncr warnings)\n");
      if(system($cmd)) {
        print("\n\nERROR: $cmd failed in $cwd\n\n");
        my $cmd = "xmessage -center \"\nRebase ERROR: $cmd failed in $cwd\n\n\"";
        exit 1;
      }   
    }
  }
  chdir($pwd);
}
if(-f "/usr/bin/xmessage") {
  my $cmd = "xmessage -center \"Rebase completed successfully in $pwd\"";
  system($cmd);
}
exit 0;
