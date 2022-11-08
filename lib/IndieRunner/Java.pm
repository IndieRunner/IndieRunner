package IndieRunner::Java;

# Copyright (c) 2022 Thomas Frohwein
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use Carp;

use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::IdentifyFiles qw( get_magic_descr );	# XXX: is this used here?
use IndieRunner::IndieRunner;

use Archive::Extract;
use Capture::Tiny ':all';
use Config;
use File::Find::Rule;
use File::Path qw( remove_tree );
use File::Spec::Functions qw( catfile splitpath );
use FindBin; use lib "$FindBin::Bin/../lib";
use JSON;
use List::Util qw( max maxstr );
use Path::Tiny;
use Readonly;

Readonly::Scalar my $CONFIG_FILE => 'config.json';

# Java version string examples: '1.8.0_312-b07'
#                               '1.8.0_181-b02'
#                               '11.0.13+8-1'
#                               '17.0.1+12-1'
Readonly::Scalar my $JAVA_VER_REGEX => '\d{1,2}\.\d{1,2}\.\d{1,2}[_\+][\w\-]+';

Readonly::Hash my %managed_subst => (
	'libgdx' =>             {
				'Bundled_Loc'         => 'com/badlogic/gdx',
				'Replace_Loc'         => '/usr/local/share/libgdx',
				'Version_File'        => 'Version.class',
				'Version_Regex'       => '\d+\.\d+\.\d+',
				'Os_Test_File'        => 'com/badlogic/gdx/utils/SharedLibraryLoader.class',
				},
	'steamworks4j' =>       {
				'Bundled_Loc'         => 'com/codedisaster/steamworks',
				'Replace_Loc'         => '/usr/local/share/steamworks4j',
				'Version_File'        => 'Version.class',
				'Version_Regex'       => '\d+\.\d+\.\d+',
				'Os_Test_File'        => 'com/codedisaster/steamworks/SteamSharedLibraryLoader.class',
				},
);

Readonly::Array my @LIB_LOCATIONS
        => ( '/usr/X11R6/lib',
	     '/usr/local/lib',
	     '/usr/local/share/lwjgl',
	     '/usr/local/share/libgdx',
);

my $Os;
Readonly::Scalar my $So_Sufx => '.so';
my $Bit_Sufx;

my %Valid_Java_Versions = (
	'openbsd'       => [
				'1.8.0',
				'11',
				'17',
			   ],
);

sub match_bin_file {
	my $regex               = shift;
	my $file                = shift;
	my $case_insensitive    = defined($_[0]);

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
	unless ( -f $bundled_java_bin ) {
		return '1.8.0';	# no file to get version from; default to 1.8.0
	}

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
	# 1. if target version is '_MAX_', then select the highest version
	# 2. returns the matching version amongst the candidates if exists, or
	# 3. returns the lowest of version numbers higher than target, or
	# 4. returns the highest candidate version among lower numbers

	die "too few arguments to subroutine" unless scalar( @_ ) > 1;

	my $target_v = shift(@_);

	# convert all arguments with version->declare
	# are all supplied arguments valid version strings? (or '_MAX_'?)
	foreach ( @_ ) {
		$_ = version->declare($_);
		unless ( $_->is_lax() ) {
			die "invalid version string argument to subroutine";
		}
	}

	# 1. if target_v is '_MAX_', return highest version
	if ( $target_v eq '_MAX_' ) {
		return max(@_);
	}

	# 2. if match exists, return the first one
	foreach my $candidate_v (@_) {
		if ( $candidate_v == $target_v ) {
			return $candidate_v;
		}
	}

	# 3. returns the lowest of version numbers higher than target, or
	foreach my $candidate_v ( sort(@_) ) {
		if ( $candidate_v > $target_v ) {
			return $candidate_v;
		}
	}

	# 4. returns the highest candidate version among lower numbers
	foreach my $candidate_v ( sort {$b cmp $a} @_ ) {
		if ( $candidate_v < $target_v ) {
			return $candidate_v;
		}
	}

	die "Unable to find a replacement version";	# this shouldn't be reached
}

sub replace_managed {
	my $framework_name = shift(@_);

	my $bundled_loc;
	my $framework_version;
	my $framework_version_file;
	my $replacement_framework;
	my $version_class_file = $managed_subst{ $framework_name }{ 'Version_File' };

	my %candidate_replacements;	# hash of location and version

	# find bundled version
	$bundled_loc	= $managed_subst{ $framework_name }{ 'Bundled_Loc' };
	unless ( -e $bundled_loc ) {
		return 1;	# the framework/managed code doesn't exist
	}
	$framework_version_file	= catfile( $bundled_loc,
					   $version_class_file );

	if ( -f $framework_version_file ) {
		$framework_version = match_bin_file( $managed_subst{ $framework_name }{ 'Version_Regex'},
					     $framework_version_file );
		say "found bundled $framework_name, version $framework_version";
	}
	else {
		say "Missing $version_class_file file for $framework_name. Picking highest available one.";
		$framework_version = '_MAX_';
	}

	# find matching replacement
	%candidate_replacements =
		map { match_bin_file( $managed_subst{ $framework_name }{ 'Version_Regex' }, $_) =>
			( splitpath($_) )[1]
		    } File::Find::Rule->file
				      ->name( $version_class_file )
				      ->in( $managed_subst{ $framework_name }{ 'Replace_Loc' } );
	$replacement_framework = $candidate_replacements{
		select_most_compatible_version( $framework_version,
						keys( %candidate_replacements ) ) };
	unless( $replacement_framework ) {
		die "No matching framework found to replace bundled $framework_name";
	}

	# remove and replace bundled version
	say "replacing bundled $framework_name at '$bundled_loc'";
	if ( -l $bundled_loc ) {
		die "Error: '$bundled_loc' is already a symlink!";
	}
	remove_tree( $bundled_loc ) or
		die "failed to delete $bundled_loc: $!";
	symlink($replacement_framework, $bundled_loc) or
		die "failed to symlink: $!";

	return 1;
}

sub replace_lib {
	my $lib = shift;

	my $lib_glob;		# pattern to search for $syslib
	my $syslib;		# the system library to replace $lib

	my @candidate_syslibs;

	# find syslib or fail
	if ( $Bit_Sufx and ( substr( $lib, -length($Bit_Sufx) ) eq $Bit_Sufx ) ) {
		# libxxx64.so => libxxx
		$lib_glob = substr($lib, 0, -length($So_Sufx));
	}
	else {
		# libxxx.so => libxxx
		$lib_glob = substr($lib, 0, -length($So_Sufx));
	}
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
	rename $lib, $lib . '_' or die "failed to rename '${lib}' -> '${lib}_': $!";
	say "symlink => $syslib";
	symlink ( $syslib, $lib ) or die "failed to create symlink: $!";

	return 1;
}

sub do_setup {
	my @class_path;
	if ( $_[0] ) {
		@class_path = @{$_[0]};
	}
	else {
		@class_path = undef;
	}

	my $bitness;
	if ( $Config{'use64bitint'} ) {
		$bitness = '64';
	}
	else {
		$bitness = '';
	}

	$Bit_Sufx = $bitness . $So_Sufx;

	# has desktop-1.0.jar been extracted?
	unless (-f 'META-INF/MANIFEST.MF') {
		if (defined $class_path[0]) {
			extract_jar(@class_path) or return 0;
		}
		else {
			extract_jar( glob( '*.jar' ) ) or return 0;
		}
	}

	# if managed code doesn't support this operating system, replace it
	foreach my $k ( keys( %managed_subst ) ) {
		if ( -e $managed_subst{ $k }{ 'Bundled_Loc' }
			and not match_bin_file($Os, $managed_subst{ $k }{ 'Os_Test_File' }, 1) ) {
			replace_managed($k) or return 0;
		}
	}

	# TODO: are all needed native libraries present? Prompt to install missing ones
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

sub run_cmd {
	my ($self, $game_file) = @_;

	my $config_data;
	my $java_home;
	my $main_class;
	my @class_path;
	my @jvm_env;
	my @jvm_args;

	carp "Warning: Preliminary implementation";

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

	@jvm_env	= ( "JAVA_HOME=$java_home", );
	return( 'env', @jvm_env, $java_home . '/bin/java', @jvm_args, $main_class );
}

sub setup {
	my ($self) = @_;
	my $dryrun = cli_dryrun;
	my $verbose = cli_verbose;

	carp "Warning: Preliminary implementation";
	do_setup;
}

1;
