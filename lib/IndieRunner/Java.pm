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
use autodie;
use Carp;

# XXX: are all of these exports really needed?
use base qw( Exporter );
our @EXPORT_OK = qw( get_java_home get_java_version match_bin_file );

#use Archive::Extract;	# XXX: Remove in favor of IO::Uncompress::Unzip?
use Config;
#use IO::Uncompress::Unzip qw($UnzipError);	# XXX: remove?
use JSON;
use Path::Tiny;
use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::Platform qw( get_os );

Readonly::Scalar my $CONFIG_FILE => 'config.json';

# Java version string examples: '1.8.0_312-b07'
#                               '1.8.0_181-b02'
#                               '11.0.13+8-1'
#                               '17.0.1+12-1'
Readonly::Scalar my $JAVA_VER_REGEX => '\d{1,2}\.\d{1,2}\.\d{1,2}[_\+][\w\-]+';

Readonly::Scalar my $So_Sufx => '.so';
my $Bit_Sufx;

Readonly::Array my @JAVA_LIB_PATH => (
	'/usr/local/lib',
	'/usr/local/share/lwjgl',
	);

my %Valid_Java_Versions = (
	'openbsd'       => [
				'1.8.0',
				'11',
				'17',
			   ],
);

my $game_jar;
my $main_class;
my @class_path;
my @jvm_env;
my @jvm_args;
my $java_home;
my $os_java_version;

sub match_bin_file {
	my $regex               = shift;
	my $file                = shift;
	my $case_insensitive    = defined($_[0]);

	my $out = $1 if ( $case_insensitive ?
		path($file)->slurp_raw =~ /($regex)/i :
		path($file)->slurp_raw =~ /($regex)/ );

	return $out;
}

sub fix_jvm_args {
	say 'JVM Args before fixing:';
	say join( ' ', @jvm_args ) . "\n";

	# replace any '-Djava.library.path=...' with a generic path
	map { $_ = (split( '=' ))[0] . join( ':', @JAVA_LIB_PATH) . ':' . (split( '=' ))[1] }
		grep( /^\-Djava\.library\.path=/, @jvm_args );

	say 'JVM Args after fixing:';
	say join( ' ', @jvm_args );
}

sub set_java_version {
	my $bundled_java_bin;

	# find bundled java binary, alternatively libjava.so or libjvm.so
	# TODO: make smarter
	$bundled_java_bin = 'jre/bin/java';
	unless ( -f $bundled_java_bin ) {
		$os_java_version = '1.8.0';	# no file to get version from; default to 1.8.0
		return;
	}

	# fetch version string from the $bundled_java_bin
	my $got_version = match_bin_file($JAVA_VER_REGEX, $bundled_java_bin);

	# trim $version_str string to OS JAVA_HOME
	if ( get_os() eq 'openbsd' ) {
		# OpenBSD: '1.8.0', '11', '17'
		if (substr($got_version, 0, 2) eq '1.') {
			$os_java_version = '1.8.0';
		}
		else {
			$os_java_version = $got_version =~ /^\d{2}/;
		}
	}
	else {
		confess "Unsupported OS: " . get_os();
	}

	# validate $os_java_version
	unless (grep( /^$os_java_version$/, @{$Valid_Java_Versions{get_os()}} )) {
		die ( "No valid Java version found in '$bundled_java_bin': ",
			"$os_java_version"
		    );
	}
}

sub get_java_version {
	return $os_java_version;
}

sub set_java_home {
	if ( get_os() eq 'openbsd' ) {
		$java_home = '/usr/local/jdk-' . get_java_version();
	}
	else {
		die "Unsupported OS: " . get_os();
	}

	confess "Couldn't locate desired JAVA_HOME directory at $java_home: $!" unless ( -d $java_home );
}

sub get_java_home {
	return $java_home;
}

=begin
### check if this should be in LibGDX.pm ###
sub extract_jar {
	my $ae;
	my @class_path = @_;

	foreach my $cp (@class_path) {
		unless ( -f $cp ) {
			croak "No classpath $cp to extract.";
		}
		say "Extracting $cp ...";
		$ae = Archive::Extract->new( archive	=> $cp,
					     type	=> 'zip' );
		$ae->extract or die $ae->error unless cli_dryrun();
	}
}
=cut

sub setup {
	my ($self) = @_;

	my $dryrun = cli_dryrun;
	my $verbose = cli_verbose;

	die "OS not recognized: " . get_os() unless ( exists $Valid_Java_Versions{get_os()} );

	# initialize key variables
	set_java_version();
	set_java_home();

	if ( -f $CONFIG_FILE ) {
		my $config_data		= decode_json(path($CONFIG_FILE)->slurp_utf8)
			or die "unable to read config data from $CONFIG_FILE: $!";
		$game_jar		= $$config_data{'jar'}
			or die "Unable to get configuration for mainClass: $!";
		$main_class		= $$config_data{'mainClass'}
			or die "Unable to get configuration for mainClass: $!";
		@class_path		= $$config_data{'classPath'}
			or die "Unable to get configuration for classPath: $!";
		@jvm_args = @{$$config_data{'vmArgs'}} if ( exists($$config_data{'vmArgs'}) );
		@jvm_env = ( "JAVA_HOME=" . get_java_home, );
	}
	else {
		# e.g. Puppy Games LWJGL game, like Titan Attacks, Ultratron
		confess "XXX: Not implemented";
	}

	my $bitness;
	if ( $Config{'use64bitint'} ) {
		$bitness = '64';
	}
	else {
		$bitness = '';
	}
	$Bit_Sufx = $bitness . $So_Sufx;

	if ( $verbose ) {
		say "Bundled Java Version: " . get_java_version();
		say "Will use Java Home " . get_java_home() . " for execution";
		say "Library suffix: $Bit_Sufx";
	}

=begin
	### check if this shoul be handled in LibGDX.pm ###
	# has main JAR archive (e.g. desktop-1.0.jar) been extracted?
	# TODO: don't extract all .jar, but the class_path file from config.json
	unless (-f 'META-INF/MANIFEST.MF') {
		extract_jar( glob( '*.jar' ) );
	}
=cut

=begin
	### EXAMPLE for how to list files from a zip/.jar archive  without extracting ###
	my $u = new IO::Uncompress::Unzip 'game.jar' or confess "Cannot open 'game.jar': $UnzipError";
	my $status;
	for ($status = 1; $status > 0; $status = $u->nextStream()) {
		say $u->getHeaderInfo()->{Name};
	}
	$u->close;
	exit;
=cut
}

sub run_cmd {
	my ($self, $game_file) = @_;

	fix_jvm_args();

	return( 'env', @jvm_env, get_java_home . '/bin/java', @jvm_args, $main_class );
}

1;
