#! /usr/bin/env perl

use strict;

use Getopt::Long;
use Cwd;
use Cwd 'chdir';


my $pwv=`gitBaseDir.pl`;
chomp($pwv);
if ($pwv eq "** NONE **") {
  system("xmessage -center \"ERROR: tests failed not in a git repo\"");
}
my $currentDir = getcwd();
my $compileOnlyDir = "/ansysdev/git/${pwv}/simplorer/Tests/New_VHDL/testcases/compile_only";
if(!chdir($compileOnlyDir)) {
  print("ERROR: could not cd to $compileOnlyDir\n");
  system("xmessage -center \"ERROR: could not cd to $compileOnlyDir\"");
  exit 1;
}

my $tmp = "/ansysdev/compilerTests/${pwv}Tests";
my $flav = "64debug";
my $si = "/ansysdev/git/${pwv}/3rdparty/MinGW/MinGW-4.8.1";
my $testcaseListFile = "testcase-list-file.txt";
my $cppDiff = "";
my $sortDiff;
my $cppGen = "";
my $repeat;
my $runSingleCompiler = 0;
my $help;

# figure out how many processors
my $j = $ENV{NUMBER_OF_PROCESSORS};
if(defined($j)) {
  print("$j processors detected\n");
} else {
  print("cannot determine numb of processors, using 4\n");
  $j = "4";
}

GetOptions("tmpFile=s" => \$tmp, # tmp file location
           "flav=s" => \$flav, # flavor
           "si=s" => \$si, # si location
           "testcaselistfile=s" => \$testcaseListFile, # testcase file
           "j=s" => \$j, # parallel value
           "cppDiff=s" => \$cppDiff,
           "sortDiff" => \$sortDiff,
           "cppGen=s" => \$cppGen,
           "repeat=s" => \$repeat,
           "runSingleCompiler" => \$runSingleCompiler,
           "help|?" => \$help, #print out help
    ) or printHelp();

if($help) {
  printHelp();
}

sub printHelp {
  print "runTests [--tmpFile <tempfile location>] [--flav <debug/release>]\n";
  print "\t[--si <si location>] [--testcaselistfile <testcase file>]\n";
  print "\t[-j <numb>] [--cppGen <dir>} [--runSingleCompiler] \n";
  print "\t[--cppDiff <dir>] [--sortDiff] [--repeat <numb>] [--help|?]\n\n";
  print "default: \n\n$0 --temp $tmp";
  print " --flav $flav";
  print " --si $si";
  print " --testcaselistfile $testcaseListFile";
  print " -j $j\n\n";
  print "HINT: to run a specified set of tests (like a single test, create a";
  print " text file \nanywhere you want and put the vhd file name (along with";
  print " any dependent vhd's) \nin the text file. then call the script with:\n";
  print "\t--testcaselistfile <path to file/text file>\n\n";
  exit 1;
}

my $cppGenSw = "";
if($cppGen) {
  $cppGenSw = "-cppGen $cppGen";
}
my $cppDiffSw = "";
if($cppDiff) {
  $cppDiffSw = "-cppDiff $cppDiff";
}
my $sortDiffSw = "";
if($sortDiff) {
  $sortDiffSw = "-sortDiff";
}
my $repeatVal = 1;
if($repeat) {
  $repeatVal = $repeat;
}
if(! -d "$tmp") {
  print("$tmp does not exist, creating ...\n");
  my @dirs = split("/",$tmp);
  chomp(@dirs);
  my $fullDir;
  foreach my $dir(@dirs) {
    if($dir) {
      print("dir = $dir\n");
      my $newFullDir = "${fullDir}/${dir}";
      if(! -d "$newFullDir") {
        if(!chdir("$fullDir")) {
          print("ERROR: cannot cd to $fullDir\n");
          exit(1);
        }
        system("cmd /C md $dir") == 0 or
            die ("ERROR: cannot mkdir $dir in $fullDir\n");
      }
      $fullDir=$newFullDir;
    }
  }
}

chdir($compileOnlyDir) or die ("ERROR: cannot chdir to $compileOnlyDir\n\n");
my $cmd = "perl ./run-tests.pl -tmp $tmp -flav $flav -si \"${si}\" -tf $testcaseListFile -d -j $j $cppDiffSw $sortDiffSw $cppGenSw 2>&1";
my $cwd = cwd();
print("\ncwd = $cwd\n");
print("\n\nrunning cmd: $cmd\n\n");
my $failed = 0;
my $count = 0;
while($count < $repeatVal) {
  if(system($cmd) != 0) {
    $failed = 1;
  }
  print("loop $count\n");
  $count = $count + 1;
}
if($failed) {
  system("xmessage -center \"FAILED: tests $cmd failed.\"");
  exit 2;
}
system("xmessage -center \"PASSED: tests $cmd passed.\"");
exit 0;

