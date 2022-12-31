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

use Archive::Extract;	# XXX: replace in favor of IO::Uncompress::Unzip?
use Config;
use File::Find::Rule;
use JSON;
use Path::Tiny;
use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::Java::LibGDX;
use IndieRunner::Java::LWJGL2;
use IndieRunner::Java::LWJGL3;
use IndieRunner::Java::Steamworks4j;
use IndieRunner::Platform qw( get_os );

Readonly::Scalar my $MANIFEST		=> 'META-INF/MANIFEST.MF';

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
my $class_path;
my @java_frameworks;
my $java_home;
my @jvm_env;
my @jvm_args;
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
	print "JVM Args before fixing:\t";
	say join( ' ', @jvm_args );

	# replace any '-Djava.library.path=...' with a generic path
	map { $_ = (split( '=' ))[0] . join( ':', @JAVA_LIB_PATH) . ':' . (split( '=' ))[1] }
		grep( /^\-Djava\.library\.path=/, @jvm_args );

	print "JVM Args after fixing:\t";
	say join( ' ', @jvm_args ) . "\n";
}

sub set_java_version {
	my $bundled_java_bin;

	# find bundled java binary, alternatively libjava.so or libjvm.so
	# TODO: make smarter, e.g. File::Find::Rule for filename 'java'
	# Delver: 'jre-linux/linux64/bin/java'; is also 1.8.0
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

sub has_libgdx { ( glob '*gdx*.{so,dll}' ) ? return 1 : return 0; }
sub has_steamworks4j { ( glob '*steamworks4j*.{so,dll}' ) ? return 1 : return 0; }

sub has_lwjgl_any {
	if ( File::Find::Rule->file
			     ->name( '*lwjgl*.{so,dll}' )
			     ->in( '.' )
	   ) { return 1; }
	return 0;
}

sub lwjgl_2_or_3 {
	if ( File::Find::Rule->file
			     ->name( '*lwjgl_{opengl,remotery,stb,xxhash}.{so,dll}' )
			     ->in( '.' )
	   ) { return 3; }
	return 2;
}

sub setup {
	my ($self) = @_;

	my $dryrun = cli_dryrun;
	my $verbose = cli_verbose;

	my $config_file;

	# 1. Check OS and initialize basic variables
	die "OS not recognized: " . get_os() unless ( exists $Valid_Java_Versions{get_os()} );
	set_java_version();
	set_java_home();
	@jvm_env = ( "JAVA_HOME=" . get_java_home(), );
	$Bit_Sufx = ( $Config{'use64bitint'} ? '64' : '' ) . $So_Sufx;
	if ( $verbose ) {
		say "Bundled Java Version: " . get_java_version();
		say "Will use Java Home " . get_java_home() . " for execution";
		say "Library suffix: $Bit_Sufx";
	}


	# 2. Get data on main JAR file and more
	# 	a. first check JSON config file
	if ( -f 'config.json' ) {	# commonly config.json, but sometimes e.g. TFD.json
		$config_file = 'config.json';
	}
	else {
		($config_file) = glob '*.json';
	}

	if ( -f $config_file ) {
		my $config_data		= decode_json(path($config_file)->slurp_utf8)
			or die "unable to read config data from $config_file: $!";
		$main_class		= $$config_data{'mainClass'}
			or die "Unable to get configuration for mainClass: $!";
		$class_path		= $$config_data{'classPath'}
			or die "Unable to get configuration for classPath: $!";
		$game_jar		= $$config_data{'jar'} if ( exists($$config_data{'jar'}) );
		@jvm_args = @{$$config_data{'vmArgs'}} if ( exists($$config_data{'vmArgs'}) );
	}
	#	b. check shellscripts for the data
	else {
		#	e.g. Puppy Games LWJGL game, like Titan Attacks, Ultratron (ultratron.sh)
		#	e.g. Delver (run-delver.sh)

		# find and slurp .sh file
		my @sh_files = glob '*.sh';
		my $content;
		my @lines;
		my @java_lines;
		foreach my $sh ( @sh_files ) {
			# slurp and format content of file
			$content = path( $sh )->slurp_utf8;
			$content =~ s/\s*\\\n\s*/ /g;	# rm escaped newlines

			@lines = split( /\n/, $content );
			@lines = grep { !/^#/ } @lines;	# rm comments
			@java_lines = grep { /^java\s/ } @lines;	# find java invocation

			last if scalar @java_lines == 1;

			if ( scalar @java_lines > 1 ) {
				confess "XXX: Not implemented";
			}
		}

		# extract important stuff from the java invocation
		if ( $java_lines[0] =~ m/\-jar\s+\"?(\S+\.jar)\"?/i ) {
			$game_jar = $1;
		}
		my @java_components = split( /\s+/, $java_lines[0] );
		push @jvm_args, grep { /^\-D/ } @java_components;
	}

	# 3. Extract JAR file if not done previously
	unless (-f $MANIFEST ) {
		if ( $game_jar ) {
			extract_jar $game_jar;
		}
		elsif ( $class_path ) {
			extract_jar @{$class_path}[0];
		}
		else {
			confess "no JAR file to extract";
		}
	}

	# 4. Enumerate frameworks (LibGDX, LWJGL{2,3}, Steamworks4j)

	if ( has_libgdx() ) {
		push( @java_frameworks, 'LibGDX' );
		push( @java_frameworks, 'LWJGL' . lwjgl_2_or_3() );	# LibGDX implies LWJGL
	}
	elsif ( has_lwjgl_any() ) {
		push( @java_frameworks, 'LWJGL' . lwjgl_2_or_3() );
	}
	push @java_frameworks, 'Steamworks4j' if has_steamworks4j();
	say 'Bundled Java Frameworks: ' . join( ' ', @java_frameworks) if $verbose;

	# 5. Call specific setup for each framework
	foreach my $f ( @java_frameworks ) {
		my $module = "IndieRunner::Java::$f";
		$module->setup();
	}
}

sub run_cmd {
	my ($self, $game_file) = @_;

	fix_jvm_args();

	# more effort to figure out $main_class
	unless ( $main_class ) {
		my @mlines = path( $MANIFEST )->lines_utf8;
		map { /^\QMain-Class:\E\s+(\S+)/ and $main_class = $1 } @mlines;
	}
	confess "Unable to identify main class for JVM execution" unless $main_class;

	return( 'env', @jvm_env, get_java_home . '/bin/java', @jvm_args, $main_class );
}

1;
