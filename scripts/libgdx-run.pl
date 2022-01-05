#! /usr/bin/perl

use strict;
use warnings;
use v5.10;

use Data::Dumper;	# TODO: mainly for testing/debugging. Remove later
use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON;
use Path::Tiny;
use Readonly;

use IndieRunner::IndieRunner;

Readonly::Scalar my $CONFIG_FILE	=> 'config.json';

# version string examples: '1.8.0_312-b07', '1.8.0_181-b02', '11.0.13+8-1', 17.0.1+12-1
Readonly::Scalar my $JAVA_VER_REGEX	=> '\d{1,2}\.\d{1,2}\.\d{1,2}[_\+][\w\-]+';

my $Work_Dir;

my $Os;	
my $Os_Java_Version;	# e.g. '1.8.0'
my $Os_Java_Home;
my $Os_Java_Bin;	# e.g. '/usr/local/jdk-1.8.0/bin/java'
my $Jar_Bin;		# e.g. '/usr/local/jdk-1.8.0/bin/jar'
my @Class_Path;		# from $CONFIG_FILE, e.g. [ 'desktop-1.0.jar', ]
my $Main_Class;		# from $CONFIG_FILE, e.g. 'kaleta.hex3.desktop.DesktopLauncher'
my @Jvm_Args;		# from $CONFIG_FILE, e.g. [ '-Xmx1G', '-Xms1G', ]
my @Jvm_Env;		# JAVA_HOME, PATH, JAVACMD

my $Bundled_Java_Bin;	# bundled (Linux) JRE binary containing $Java_Ver

my $Config_Data;	# converted content from $CONFIG_FILE
my @System_Command;	# the command to be executed with all parameters as array

my %Valid_Java_Versions = (
	'openbsd'	=> [
				'1.8.0',
				'11',
				'17',
			   ],
);

sub get_java_version {
	$Bundled_Java_Bin = 'jre/bin/java';	# alternatives:	jre/lib/amd64/libjava.so
						#		jre/lib/amd64/libjvm.so`

	# fetch version string from the $Bundled_Java_Bin
	my $java_bin_content = path($Bundled_Java_Bin)->slurp_raw;
	my $got_version = $1 if ($java_bin_content =~ /($JAVA_VER_REGEX)/);

	# trim $version_str string to OS JAVA_HOME
	if ( $Os eq 'openbsd' ) {
		# OpenBSD: '1.8.0', '11', '17'
		if (substr($got_version, 0, 2) eq '1.') {
			$Os_Java_Version = '1.8.0';
		}
		else {
			$Os_Java_Version = $got_version =~ /^\d{2}/;
		}
	}
	else {
		die "Unsupported OS: $Os";
	}

	# validate $Os_Java_Version
	unless (grep( /^$Os_Java_Version$/, @{$Valid_Java_Versions{$Os}} )) {
		die ( "No valid Java version found in '$Bundled_Java_Bin': ",
			"$Os_Java_Version"
		    );
	}

	return $Os_Java_Version;
}

sub run {

	# get OS
	$Os = IndieRunner::IndieRunner::detectplatform;
	unless ( exists $Valid_Java_Versions{$Os} ) {
		die "OS not recognized: $Os";
	}

	# slurp and assign config data
	$Config_Data		= decode_json(path($CONFIG_FILE)->slurp_utf8)
		or die "unable to read config data from $CONFIG_FILE: $!";
	@Class_Path		= $$Config_Data{'classPath'}
		or die "Unable to get configuration for classPath: $!";
	$Main_Class		= $$Config_Data{'mainClass'}
		or die "Unable to get configurarion for mainClass: $!";
	if ( exists($$Config_Data{'vmArgs'}) ) {
		@Jvm_Args	= $$Config_Data{'vmArgs'}
	}

	print Dumper($Os, @Class_Path, $Main_Class, @Jvm_Args);
}

run;
