#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';

my $firstDir;
my $secondDir;
my $help;

GetOptions("1=s" => \$firstDir,
           "2=s" => \$secondDir,
           "help|?" => \$help,
    ) or printHelp();

printHelp() if($help);

sub printHelp
{
  print("\ndiffDirFiles -1 <first dir> -2 <second dir> [-help|?]\n");
  exit 1;
}

my $pwd = cwd();
if(! -d $firstDir) {
  die("ERROR: cannot find $firstDir\n\n");
}
if(! -d $secondDir) {
  die("ERROR: cannot find $secondDir\n\n");
}
if(!chdir($firstDir)) {
  die("ERROR: cannot chdir to $firstDir\n\n");
}
my @files = qx/ls -1/;
chomp(@files);
for my $file(@files) {
  if(-f $file) {
    my $otherFile = "$secondDir/$file";
    if(! -f $otherFile) {
      print("$file exists in $firstDir but not $secondDir\n\n");
    } else {
      my $diff = system("diff $firstDir/$file $secondDir/$file > /dev/null 2>&1");
      if($diff) {
        print("$file has diff's, starting emacs\n\n");
        my $evalcmd = "ediff-files \\\"$secondDir/$file\\\" \\\"$file\\\"";
        my $cmd = "d:/emacs-24.3/bin/runemacs.exe --eval \"($evalcmd)\" 2>&1 >/dev/null";
        print("exec'ing $cmd\n");
        system("$cmd");
        print("\n\nHit return to advance to next\n\n");
        my $waitForReturn = <STDIN>;
      }
    }
  }
}
