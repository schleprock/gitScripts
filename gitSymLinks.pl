#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';
use Time::HiRes qw(time);

my $help;
my $undo;

GetOptions("undo" => \$undo, #undo the symlinks
           "help|?" => \$help,
    );
printHelp() if($help);

sub printHelp
{
  print("\ngitSymLinks [--undo] [-help|?]\n");
  print("\n\t--undo: undo the symlinks\n");
  exit;
}
my @repos = ("build",
             "buildtools",
             "Ansys_CDU_nosync",
             "Ansys_CDU_sync",
             "thirdparty",
             "thirdparty_opensrc",
             "thirdparty_vob2",
             "sj_thirdparty",
             "CodeDV",
             "Core_Addin",
             "simplorer",
             "nextgen",
             "ansoft",
             "bostonvob");

my $pwd = getcwd();

my $gitBash = " ";
#my $gitBash = "/c/Program\\ Files\\ \\(x86\\)/Git/bin/sh.exe";
my $winSym = "../buildtools/scripts/git/fix-symlinks.sh";
my $fixUndo = "Fixing";
if($undo) {
  $winSym = "../buildtools/scripts/git/undo-symlinks.sh";
  $fixUndo = "Undo'ing";
}
my $totalTimeStart = time();
foreach my $dir(@repos) {
  if(!chdir($dir)) {
    if(-f "/usr/bin/xmessage") {
      $ENV{DISPLAY} = "127.0.0.1:0.0";
      my $cmd  = "xmessage -center \"ERROR: gitSymLinks failed could not cd to $dir\"";
      system($cmd);
    }
    die("ERROR: could not cd to $dir\n\n");
  }
  my $here = getcwd();
  print("\n$fixUndo $here:\n");
  if(! -r $winSym) {
      die "\nERROR: cannot find $winSym\n\n";
  }
  my $start = time();
  my $cmd = "$gitBash $winSym";
  system($cmd);
  my $end = time();
  printf("$dir took %.2f seconds\n", $end - $start);
  chdir($pwd);
}
my $totalTimeEnd = time();
printf("\n\nTotal time took %.2f seconds\n", $totalTimeEnd - $totalTimeStart);
if(-f "/usr/bin/xmessage") {
  $ENV{DISPLAY} = "127.0.0.1:0.0";
  my $cmd = "xmessage -center \"gitSymLinks completed in $pwd\"";
  system($cmd);
}
