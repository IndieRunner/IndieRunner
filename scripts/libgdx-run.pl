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

my $Os;	

my %Valid_Java_Versions = (
	'openbsd'	=> [
				'1.8.0',
				'11',
				'17',
			   ],
);

sub get_java_version {
	my $bundled_java_bin;
	my $os_java_version;

	# find bundled java binary, alternatively libjava.so or libjvm.so
	# TODO: make smarter
	$bundled_java_bin = 'jre/bin/java';

	# fetch version string from the $bundled_java_bin
	my $java_bin_content = path($bundled_java_bin)->slurp_raw;
	my $got_version = $1 if ($java_bin_content =~ /($JAVA_VER_REGEX)/);

	# trim $version_str string to OS JAVA_HOME
	if ( $Os eq 'openbsd' ) {
		# OpenBSD: '1.8.0', '11', '17'
		if (substr($got_version, 0, 2) eq '1.') {
			$os_java_version = '1.8.0';
		}
		else {
			$os_java_version = $got_version =~ /^\d{2}/;
		}
	}
	else {
		die "Unsupported OS: $Os";
	}

	# validate $os_java_version
	unless (grep( /^$os_java_version$/, @{$Valid_Java_Versions{$Os}} )) {
		die ( "No valid Java version found in '$bundled_java_bin': ",
			"$os_java_version"
		    );
	}

	return $os_java_version;
}

sub get_java_home {
	my $java_home;

	if ( $Os eq 'openbsd' ) {
		$java_home = '/usr/local/jdk-' . get_java_version;
	}
	else {
		die "Unsupported OS: $Os";
	}

	-d $java_home ? return $java_home :
		die "failed to get JAVA_HOME directory at $java_home: $!";
}

sub run {
	my $config_data;
	my $qx_string;
	my $java_home;
	my $main_class;
	my @class_path;
	my @jvm_env;
	my @jvm_args;
	my @system_args;

	# get OS and OS Java variables
	$Os = IndieRunner::IndieRunner::detectplatform;
	unless ( exists $Valid_Java_Versions{$Os} ) {
		die "OS not recognized: $Os";
	}
	$java_home = get_java_home;

	# slurp and assign config data
	$config_data		= decode_json(path($CONFIG_FILE)->slurp_utf8)
		or die "unable to read config data from $CONFIG_FILE: $!";
	$main_class		= $$config_data{'mainClass'}
		or die "Unable to get configurarion for mainClass: $!";
	@class_path		= $$config_data{'classPath'}
		or die "Unable to get configuration for classPath: $!";
	if ( exists($$config_data{'vmArgs'}) ) {
		@jvm_args	= @{$$config_data{'vmArgs'}};
	}

	# build command and execute
	# TODO: call JVM directly via PBJ::JNI or Jvm from CPAN; better portability?
	@jvm_env	= (
				"JAVA_HOME=$java_home",
				"PATH=$java_home/bin:\$PATH"
			  );
	@system_args = ( 'env', @jvm_env, 'java', @jvm_args, $main_class );
	say "\nExecuting Jave Virtual Machine:";
	say join( ' ', @system_args ) . "\n";
	$qx_string = join( ' ', ( @system_args, '2>&1 > indierun.log' ) );
	qx($qx_string);
	say "Execution completed with exit code " . ($? >> 8);
}

run;
