#! /usr/bin/env perl

use strict;
use Getopt::Long;
use Cwd;
use Cwd 'chdir';

my $repoSet = "";
my $version = "debug";
my $dllDir = "./libdir";
my $tempDir = ".";
my $simplorerInstallDir = "\"c:/Program Files/AnsysEM/AnsysEM17.0/Win64/\"";
my $help;

GetOptions("repoSet=s" => \$repoSet,
           "version=s" => \$version,
           "simplorerInstallDir=s" => \$simplorerInstallDir,
           "dllDir=s" => \$dllDir,
           "tempDir=s" => \$tempDir,
           "help|?" => \$help,
    ) or printHelp();

if($help) {
  printHelp();
  exit(0);
}

sub printHelp {
  print("runVHDLamsParser.pl --repoSet <repoSet dir name> ");
  print("[--version <debug/release>]\n\t[--simplorerInstallDir <path to ");
  print("simplorer install>]\n\t[--dllDir <path to dependent vhdl dll's>]\n\t");
  print("[--tempDir <path to temp dir>]\n\t[--help]\n\n");
  print("Default is: --version debug\n\t--simplorerInstallDir ");
  print("\"c:/Program Files/AnsysEM/AnsysEM17.0/Win64/\"\n\t--dllDir ");
  print("./libdir --tempDir .\n\n");
}

if("$repoSet" eq "") {
  print("\n\nERROR: repo set directory name must be specified.\n\n");
  printHelp();
  exit(1);
}

my $vhdlExe;
if(-d $repoSet) {
  $vhdlExe = "${repoSet}/build_output/64${version}/vhdl_ams_parser.exe";
} else {
  $vhdlExe = "/ansysdev/git/${repoSet}/build_output/64${version}/";
  $vhdlExe = "${vhdlExe}vhdl_ams_parser.exe";
}

if(! -x $vhdlExe) {
  print("\n\nERROR: $vhdlExe could not be found or is not executable\n\n");
  exit(2);
}

my $vhdlSrcFile;
if(@ARGV == 1) {
  $vhdlSrcFile = $ARGV[0];
} else {
  ## try to find a vhd or vhdl file...
  my @vhdlFiles = qx!ls -1 *.vhd *.vhdl 2>/dev/null!;
  chomp(@vhdlFiles);
  if(@vhdlFiles > 1) {
    print("ERROR: no vhd<l> file specified and more than 1 found:\n");
    foreach my $vhdlFile(@vhdlFiles) {
      print("\t$vhdlFile\n");
    }
    print("\nYou must specify a vhd<l> file.\n\n");
    printHelp();
    exit(7);
  } elsif(@vhdlFiles == 1) {
    $vhdlSrcFile = $vhdlFiles[0];
  } else {
    print("ERROR: no vhd<l> file specified and none found.\n");
    print("\tYou must specify a vhd<l> file.\n\n");
    printHelp();
    exit(8);
  }
  print("\nNOTE: no vhd<l> file specified but found $vhdlSrcFile\n\n");
}

if(! -e $vhdlSrcFile) {
  print("\n\nERROR: cannot find $vhdlSrcFile\n\n");
  exit(4);
}

my $cmd = "$vhdlExe --standalone $dllDir $tempDir $simplorerInstallDir ";
$cmd = "${cmd}${vhdlSrcFile}";
print("\n\nExec'ing: $cmd\n\n");

my $ret = system("$cmd");
