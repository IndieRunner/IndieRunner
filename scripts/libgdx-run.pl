#! /usr/bin/perl

use strict;
use warnings;
use v5.10;

use version 0.77;

use Archive::Extract;
use Capture::Tiny ':all';
use Config;
use File::Find::Rule;
use File::Path qw( remove_tree );
use File::Spec::Functions qw( catfile splitpath );
use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON;
use List::Util qw( maxstr );
use Path::Tiny;
use Readonly;

use IndieRunner::IndieRunner;

Readonly::Scalar	my $CONFIG_FILE		=> 'config.json';

# Java version string examples:	'1.8.0_312-b07'
#				'1.8.0_181-b02'
#				'11.0.13+8-1'
#				'17.0.1+12-1'
Readonly::Scalar	my $JAVA_VER_REGEX
				=> '\d{1,2}\.\d{1,2}\.\d{1,2}[_\+][\w\-]+';

# LibGDX version string examples:	'1.9.9'
Readonly::Scalar	my $LIBGDX_VER_REGEX	=> '\d+\.\d+\.\d+';

# TODO: remove the /usr/ports one... this is only while testing before
#	multiversion libgdx port
Readonly::Array		my @LIBGDX_REPLACE_LOCATIONS
				=> ( '/usr/local/share/libgdx',
				     '/usr/ports/pobj/libgdx-1.9.9/fake-amd64/usr/local/share/libgdx',
				   );

Readonly::Array		my @LIB_LOCATIONS
				=> ( '/usr/X11R6/lib',
				     '/usr/local/lib',
				     '/usr/local/share/lwjgl',
				     '/usr/local/share/libgdx',
				   );

my $Os;	
my $So_Sufx;

my %Valid_Java_Versions = (
	'openbsd'	=> [
				'1.8.0',
				'11',
				'17',
			   ],
);

sub match_bin_file {
	my $regex		= shift(@_);
	my $file		= shift(@_);
	my $case_insensitive	= defined($_[0]);

	my $out = $1 if ( $case_insensitive ?
			  path($file)->slurp_raw =~ /($regex)/i :
			  path($file)->slurp_raw =~ /($regex)/ );

	return $out;
}

sub get_java_version {
	my $bundled_java_bin;
	my $os_java_version;

	# find bundled java binary, alternatively libjava.so or libjvm.so
	# TODO: make smarter
	$bundled_java_bin = 'jre/bin/java';

	# fetch version string from the $bundled_java_bin
	my $got_version = match_bin_file($JAVA_VER_REGEX, $bundled_java_bin);

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

	if ( -d $java_home ) {
		return $java_home
	}
	else {
		die "failed to get JAVA_HOME directory at $java_home: $!";
	}
}

sub extract_jar {
	my $ae;
	my @class_path = @_;

	foreach my $cp (@class_path) {
		unless ( -f $cp ) {
			say "No classpath $cp to extract.";
			return 0;
		}
		say "Extracting $cp ...";
		$ae = Archive::Extract->new( archive	=> $cp,
					     type	=> 'zip' );
		unless ($ae->extract) {
			say "Couldn't extract $cp";
			return 0;
		}
	}

	return 1;
}

sub select_most_compatible_version {
	# takes target version, followed by array of candidate version numbers
	# as argument (@_)
	# 1. returns the matching version amongst the candidates if exists, or
	# 2. returns the lowest of version numbers higher than target, or
	# 3. returns the highest candidate version among lower numbers

	die "too few arguments to subroutine" unless scalar( @_ ) > 1;

	# convert all arguments with version->parse
	# are all supplied arguments valid version strings?
	foreach ( @_ ) {
		$_ = version->parse($_);
		unless ( $_->is_lax() ) {
			die "invalid version string argument to subroutine";
		}
	}

	# 1. if match exists, return the first one
	my $target_v = shift(@_);
	foreach my $candidate_v (@_) {
		if ( $candidate_v == $target_v ) {
			die "MATCH! $candidate_v ... though not implemented fully; aborting";
		}
	}

	die "not implemented";
}

sub replace_managed_framework {
	my $bundled_framework;
	my $framework_version;
	my $framework_version_file;
	my $replacement_framework;
	my $version_class_file = 'Version.class';

	my %candidate_replacements;	# hash of location and version

	# find version of bundled libgdx
	$bundled_framework	= 'com/badlogic/gdx';
	$framework_version_file	= catfile( $bundled_framework,
					   $version_class_file );
	unless ( -f $framework_version_file ) {
		die "missing LibGDX $version_class_file file";
	}
	$framework_version = match_bin_file( $LIBGDX_VER_REGEX,
					     $framework_version_file );
	say 'found bundled libgdx version: ' . $framework_version;

	# find matching libgdx replacement
	%candidate_replacements =
		map { ( splitpath($_) )[1] =>
				match_bin_file($LIBGDX_VER_REGEX, $_)
		    } File::Find::Rule->file
				      ->name( $version_class_file )
				      ->in( @LIBGDX_REPLACE_LOCATIONS );

	use Data::Dumper;
	print Dumper \%candidate_replacements;
	select_most_compatible_version( $framework_version,
					values( %candidate_replacements )
				      );
	say "Work in progress";
	exit;

	#foreach my $candidate (@candidate_replacements) {
		#if ( match_bin_file( $LIBGDX_VER_REGEX, $candidate ) eq
		     #$framework_version ) {
			#$replacement_framework = ( splitpath($candidate) )[1];
			#say 'found matching replacement version: ' .
			    #$replacement_framework;
		#}
	#}

	unless( $replacement_framework ) {
		die "No matching framework found to replace the bundled one.";
	}

	# remove and replace bundled libgdx
	say "replacing bundled LibGDX at '$bundled_framework'";
	if ( -l $bundled_framework ) {
		die "Error: '$bundled_framework' is already a symlink!";
	}
	remove_tree( $bundled_framework ) or
		die "failed to delete $bundled_framework: $!";
	symlink($replacement_framework, $bundled_framework) or
		die "failed to symlink: $!";

	return 1;
}

sub replace_lib {
	my $lib = shift;

	my $lib_glob;		# pattern to search for $syslib
	my $syslib;		# the system library to replace $lib

	my @candidate_syslibs;

	# find syslib or fail
	$lib_glob = substr($lib, 0, -length($So_Sufx));	# libxxx64.so => libxxx
	$lib_glob = $lib_glob . "{64,}.so*";		# libxxx => libxxx{64,}.so*
	@candidate_syslibs =
		File::Find::Rule->file
				->name( $lib_glob )
				->in( @LIB_LOCATIONS );
	my $n = scalar(@candidate_syslibs);
	if ( $n == 0 ) {
		say 'not found';
		return 0;
	}
	elsif ( $n == 1 ) {
		$syslib = $candidate_syslibs[0];
	}
	else {
		# 2 scenarios: differently named files in same dir
		# or files in different directories
		# the latter shouldn't happen... (famous last words)
		# List::Util::maxstr picks e.g. libopenal.so.4.1 over
		# libopenal64.so.4.0
		$syslib = maxstr( @candidate_syslibs );
	}

	# symlink to syslib
	unlink ( $lib ) or die "failed to unlink '$lib': $!";
	say "symlink => $syslib";
	symlink ( $syslib, $lib ) or die "failed to create symlink: $!";

	return 1;
}

sub do_setup {
	my @class_path			= @{$_[0]};

	my $bitness;
	if ( $Config{'use64bitint'} ) {
		$bitness = '64';
	}
	else {
		$bitness = '';
	}

	$So_Sufx = $bitness . '.so';

	my $managed_file_to_test
		= 'com/badlogic/gdx/utils/SharedLibraryLoader.class';

	# has desktop-1.0.jar been extracted?
	unless (-f 'META-INF/MANIFEST.MF') {
		extract_jar(@class_path) or return 0;
	}

	# does libgdx managed code framework support this operating system?
	unless ( match_bin_file($Os, $managed_file_to_test, 1) ) {
		replace_managed_framework or return 0;
	}

	# TODO: are all needed native libraries present?
	say "Checking which libraries are present...";
	my @bundled_libs	= glob( '*' . $So_Sufx );
	my ($f, $l);	# f: regular file test, l: symlink test
	foreach my $file (@bundled_libs) {
		print $file . ' ... ';
		($f, $l) = ( -f $file , -l $file );

		# F L: symlink to existing file => everything ok
		# F l: non-symlink file => needs fixing
		# f L: broken symlink => needs fixing
		# f l: no file found (impossible after glob above)
		if ($f and $l) {
			say 'ok';
			next;
		}
		else {
			replace_lib($file) or
				say "couldn't set up library: $file";
		}
	}

	return 1;
}

sub run {
	my $config_data;
	my $java_home;
	my $main_class;
	my $stdout;
	my $stderr;
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

	do_setup(@class_path) or die "Couldn't set up the game";

	# build command and execute
	# TODO: call JVM directly via PBJ::JNI or Jvm from CPAN; better portability?
	@jvm_env	= (
				"JAVA_HOME=$java_home",
				"PATH=$java_home/bin:\$PATH"
			  );
	@system_args = ( 'env', @jvm_env, 'java', @jvm_args, $main_class );
	say "\nExecuting Java Virtual Machine:";
	say join( ' ', @system_args ) . "\n";
	($stdout, $stderr) = tee {
		system( '/bin/sh', '-c', join( ' ', @system_args ) );
	};

	say "\nExecution completed with exit code " . ($? >> 8);
	say "STDOUT:\n$stdout";
	say "STDERR:\n$stderr";
}

run;
