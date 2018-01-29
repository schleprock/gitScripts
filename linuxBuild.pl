#! /usr/bin/env perl

use strict;

use Getopt::Long qw(:config pass_through);
use Cwd;
use Cwd 'chdir';

my $buildType = "debug";
my $buildBits = 64;
my $j;
my $clean = 0;
my $core;
my $fortranLibs;
my $designerUI;
my $simpSolver;
my $noxmessage;
my $help;

GetOptions("type=s" => \$buildType, # debug, release ...
           "clean" => \$clean, # clean build or not, default is not
           "bits=s" => \$buildBits, # numb bits, 32/64
           "j=i" => \$j, # numb parallel builds
           "core" => \$core, #build on only core
           "fortranLibs" => \$fortranLibs, # build only fortranlibs
           "designerUI" => \$designerUI, # build only designerUI
           "simpSolver" => \$simpSolver, # build only simplorer solver
           "noxmessage" => \$noxmessage, # suppress xmessages
           "help|?" => \$help, # print out help
    ) or printHelp();

if($ARGV[0]) {
  print("ERROR: unknown option $ARGV[0]; aborting\n\n");
  printHelp();
  exit(1);
}

if($help) {
  printHelp();
}

sub printHelp
{
  print "build [--type <debug/release>] [--bits <32/64>]\n";
  print "\t[ --core | --fortranLibs || --designerUI || --simpSolver ]\n";
  print "\t[ --clean ] [--j numbCpus] [--help]\n\n";
  print "default is -t debug -b 64\n";
  print "\t--type: type of build debug/release\n";
  print "\t--bits: 32/64 bit build\n";
  print "\t--core/fortranlibs/designerUI/simpSolver only build that sln\n";
  print "\t--clean: invoke clean before each build\n";
  print "\t--j: numb cpu's\n";
  print "\t--help|?: print out this message\n\n";
  exit 1;
}

my $all = 1;
if($core || $fortranLibs || $designerUI || $simpSolver) {
  $all = 0;
}

my $cleanSwitch = "";
if($clean) {
  $cleanSwitch = "--clean";
}


my $numbCPUs = $ENV{NUMBER_OF_PROCESSORS};
my $kernelName = `uname -s`;
if("$kernelName" eq "Linux") {
  $numbCPUs = `nproc`;
}
if(! defined($numbCPUs)) {
  print("cannot determine numb of processors, using 4\n");
  $numbCPUs = "4";
}
chomp($numbCPUs);
if($j) {
  $numbCPUs = $j;
}
print "\nINFO: using $numbCPUs cpu's\n";

my $buildSwitch = "";
if("$buildType" eq "debug"){
  $buildSwitch = "--debug=full";
}

if($all || $core) {
  my $cmd = "./DevTools/build/scripts/BuildSln.pl --build ./DevTools/build/OfficialSln/Core.sln --verbose --nparallel $numbCPUs $buildSwitch $cleanSwitch --nokeep-going";
  print "\nexecing: $cmd\n\n";
  if(system($cmd) != 0) {
    print("ERROR: $cmd FAILED\n\n");
    if(!$noxmessage) {
      system("xmessage -center \"ERROR: $cmd FAILED\"");
    }
    exit 1;
  }
}

if($all || $fortranLibs) {
  my $cmd = "./DevTools/build/scripts/BuildSln.pl --build ./DevTools/build/OfficialSln/FortranLibs.sln --verbose --nparallel $numbCPUs $buildSwitch $cleanSwitch --nokeep-going";
  print "\nexecing: $cmd\n\n";
  if(system($cmd) != 0) {
    print("ERROR: $cmd FAILED\n\n");
    if(!$noxmessage) {
      system("xmessage -center \"ERROR: $cmd FAILED\"");
    }
    exit 1;
  }
}

if($all || $designerUI) {
  my $cmd = "./DevTools/build/scripts/BuildSln.pl --build ./DevTools/build/OfficialSln/Designer-UI.sln --verbose --nparallel $numbCPUs $buildSwitch $cleanSwitch --nokeep-going";
  print "\nexecing: $cmd\n\n";
  my $ret = system($cmd);
  print "\ncmd returned $ret\n";
  if($ret != 0) {
    print("ERROR: $cmd FAILED\n\n");
    if(!$noxmessage) {
      system("xmessage -center \"ERROR: $cmd FAILED\"");
    }
    exit 1;
  }
}

if($simpSolver) {
  my $cmd = "./DevTools/build/scripts/BuildSln.pl --build ./DevTools/build/OfficialSln/SimplorerSolver.sln --verbose --nparallel $numbCPUs $buildSwitch $cleanSwitch --nokeep-going";
  print "\nexecing: $cmd\n\n";
  if(system($cmd) != 0) {
    print("ERROR: $cmd FAILED\n\n");
    if(!$noxmessage) {
      system("xmessage -center \"ERROR: $cmd FAILED\"");
    }
    exit 1;
  }
}

# if we got here, then it passed!
print("SUCCESS: linux built!\n\n");
if(!$noxmessage) {
  system("xmessage -center \"SUCCESS: linux built!\"");
}
