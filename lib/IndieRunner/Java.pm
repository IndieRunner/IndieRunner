package IndieRunner::Java;

# Copyright (c) 2022-2023 Thomas Frohwein
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
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use autodie;
use English;

use parent 'IndieRunner::Engine';

use Config;
use File::Find::Rule;
use File::Spec::Functions qw( catfile splitpath );
use JSON;
use List::Util qw( max );
use Path::Tiny;
use Readonly;

use IndieRunner::Java::LibGDX;
use IndieRunner::Java::LWJGL2;
use IndieRunner::Java::LWJGL3;
use IndieRunner::Java::Steamworks4j;

Readonly::Scalar my $MANIFEST		=> 'META-INF/MANIFEST.MF';

# Java version string examples: '1.8.0_312-b07'
#                               '1.8.0_181-b02'
#                               '11.0.13+8-1'
#                               '17.0.1+12-1'
Readonly::Scalar my $JAVA_VER_REGEX => '\d{1,2}\.\d{1,2}\.\d{1,2}[_\+][\w\-]+';

Readonly::Scalar my $So_Sufx => '.so';
my $Bit_Sufx;

Readonly::Array my @LIB_LOCATIONS => (
	'/usr/X11R6/lib',
	'/usr/local/lib',
	# XXX: make lwjgl location conditional; it interferes with e.g. Songs of Syx
	'/usr/local/share/lwjgl',
	);

Readonly::Array my @SKIP_FRAMEWORKS => (
	'TitanAttacks.jar',
	'Airships_sysjava.sh',
	);

Readonly::Array my @JAVA_LINE_PATTERNS => (
	'^java\s',
	'\-Xbootclasspath',
	'\-Djava\.',
	'\s\-cp\s',
	);

Readonly::Array my @INVALID_CONFIG_FILES => (
	'uiskin.json',
	);

Readonly::Array my @JAR_MODE_FILES => (
	'Airships',
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
my @java_frameworks;
my $java_home;
my @jvm_args;
my @jvm_classpath;
my @jvm_env;

my %java_version = (
	bundled	=> 0,
	lwjgl3	=> 0,
	);

# TODO: move this into a different module; possibly IdentifyFiles.pm, Misc.pm, or Helpers.pm
sub match_bin_file ( $regex, $file, $case_insensitive = 0 ) {
	my $out = $1 if ( $case_insensitive ?
		path($file)->slurp_raw =~ /($regex)/i :
		path($file)->slurp_raw =~ /($regex)/ );
	return $out;
}

sub fix_jvm_args () {
	my @initial_jvm_args = @jvm_args;

	# replace any '-Djava.library.path=...' with a generic path
	@jvm_args = grep { !/^\-Djava\.library\.path=/ } @initial_jvm_args;
	# have to keep '.' separate from @LIB_LOCATIONS to avoid creating symlink loops
	push @jvm_args, '-Djava.library.path=' . join( ':', @LIB_LOCATIONS, '.' );
}

sub get_bundled_java_version () {
	my $bundled_java_bin;

	# find bundled java binary (alternatively libjava.so or libjvm.so)
	($bundled_java_bin) = File::Find::Rule->file->name('java')->in('.');
	return undef unless $bundled_java_bin;

	# fetch version string and trim to format for JAVA_HOME
	my $got_version = match_bin_file($JAVA_VER_REGEX, $bundled_java_bin);
	if ( $OSNAME eq 'openbsd' ) {
		# OpenBSD: '1.8.0', '11', '17'
		if (substr($got_version, 0, 2) eq '1.') {
			$java_version{ bundled } = '1.8.0';
		}
		else {
			$java_version{ bundled } = substr( $got_version, 0, 2 );
		}
	}
	else {
		die "Unsupported OS: " . $OSNAME;
	}
}

sub set_java_home ( $v ) {
	if ( $OSNAME eq 'openbsd' ) {
		$java_home = '/usr/local/jdk-' . $v;
	}
	else {
		die "Unsupported OS: " . $OSNAME;
	}
	die "Couldn't locate desired JAVA_HOME directory at $java_home: $!"
		unless ( -d $java_home );
}

sub replace_lib ( $lib ) {
	my $lib_glob;           # pattern to search for $syslib

	# create glob string 'libxxx{64,}.so*'
	$lib_glob = (splitpath( $lib ))[2];
	$lib_glob =~ s/(64)?.so$//;
	$lib_glob = $lib_glob . "{64,}.so*";

	foreach my $l ( @LIB_LOCATIONS ) {
		my $candidate_file = glob( catfile( $l, $lib_glob ) );
		if ( $candidate_file and -e $candidate_file ) {
			return $candidate_file;
		}
	}

	return '';
}

sub bundled_libraries () {
	my %symlink_libs;

	#say "\nChecking which libraries are present...";
	my @bundled_libs	= File::Find::Rule->file
						  ->name( '*' . $So_Sufx )
						  ->in( '.');

	# ignore anything in jre/
	@bundled_libs	= grep { !/\Qjre\/\E/ } @bundled_libs;

	my ($f, $l);    # f: regular file test, l: symlink test
	foreach my $file (@bundled_libs) {
		#print $file . ' ... ' if ( $verbose or $dryrun );
		($f, $l) = ( -f $file , -l $file );

		# F L: symlink to existing file => everything ok
		# F l: non-symlink file => needs fixing
		# f L: broken symlink => needs fixing
		# f l: no file found (impossible after glob above)
		if ($f and $l) {
			next;
		}
		elsif ( my $replacement = replace_lib( $file ) ) {
			$symlink_libs{ $file } = $replacement;
		}
	}

	return %symlink_libs;
}

sub has_libgdx () {
	( glob '*gdx*.{so,dll}' ) ? return 1 : return 0;
}

sub has_steamworks4j () {
	( glob '*steamworks4j*.{so,dll}' ) ? return 1 : return 0;
}

sub has_lwjgl_any () {
	if ( File::Find::Rule->file
			     ->name( '*lwjgl*.{so,dll}' )
			     ->in( '.' )
	   ) { return 1; }
	return 0;
}

sub lwjgl_2_or_3 () {
	if ( File::Find::Rule->file
			     ->name( '*lwjgl_{opengl,remotery,stb,xxhash}.{so,dll}' )
			     ->in( '.' )
	   ) { return 3; }
	return 2;
}

sub skip_framework_setup () {
	foreach my $g ( @SKIP_FRAMEWORKS ) {
		return 1 if -e $g;
	}
	return 0;
}

sub test_jar_mode () {
	foreach my $j ( @JAR_MODE_FILES ) {
		return 1 if -e $j;
	}
	return 0;
}

sub new ( $class, %init ) {
	my %need_to_extract;

	my $config_file;
	my $class_path_ptr;

	my $self = bless {}, $class;
	%$self = ( %$self, %init );

	# 1. Check OS and initialize basic variables
	die "OS not recognized: " . $OSNAME unless ( exists $Valid_Java_Versions{$OSNAME} );
	get_bundled_java_version();

	$Bit_Sufx = ( $Config{'use64bitint'} ? '64' : '' ) . $So_Sufx;

	# 2. Get data on main JAR file and more
	# 	a. first check JSON config file
	#	   prioritize *config.json, e.g. for Airships: Conquer the Skies, Lenna's Inception
	#	   commonly config.json, but sometimes e.g. TFD.json
	($config_file) = glob '*config.json';
	($config_file) = glob '*.json' unless $config_file;
	if ( $config_file and ( grep { /^\Q$config_file\E$/ } @INVALID_CONFIG_FILES or ! -e $config_file ) ) {
		undef $config_file;
	}

	if ( $config_file ) {
		my $config_data		= decode_json(path($config_file)->slurp_utf8)
			or die "unable to read config data from $config_file: $!";
		$main_class		= $$config_data{'mainClass'}
			or die "Unable to get configuration for mainClass: $!";
		$class_path_ptr = $$config_data{'classPath'} if ( exists($$config_data{'classPath'}) );
		$game_jar = $$config_data{'jar'} if ( exists($$config_data{'jar'}) );
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

			# find java invocation
			foreach my $r ( @JAVA_LINE_PATTERNS ) {
				@java_lines = grep { /$r/ } @lines;
				last if scalar @java_lines == 1;
			}

			if ( scalar @java_lines > 1 ) {
				die "XXX: Not implemented";
			}
		}

		# extract important stuff from the java invocation
		if ( @java_lines ) {
			# first remove anything with variable invocations that we can't resolve
			$java_lines[0] =~ s/\s?[^\s]*\$\{\S+\}[^\s]*\s?/ /g;
			if ( $java_lines[0] =~ s/\-jar\s+\"?(\S+\.jar)\"?//i ) {
				$game_jar = $1;
			}
			if ( $java_lines[0] =~ s/-cp\s+\"?(\S+)\"?// ) {
				@jvm_classpath = split /:/, $1;
			}
			while ( $java_lines[0] =~ s/\s?(\-[DX]\S+)/ / ) {
				push @jvm_args, $1;
			}
			if ( $java_lines[0] =~ s/\s(([[:alnum:]]+\.){2,}[[:alnum:]]+)\s/ / ) {
				$main_class = $1 unless $main_class;
			}
		}
	}

	# 3. Extract JAR file if not done previously
	unless ( -f $MANIFEST or test_jar_mode ) {
		if ( $game_jar ) {
			$need_to_extract{ $game_jar } =
				__PACKAGE__ . '::extract_jar';
		}
		elsif ( $class_path_ptr ) {
			$need_to_extract{ @{$class_path_ptr}[0] } =
				__PACKAGE__ . '::extract_jar';
		}
		else {
			die "No JAR file to extract" unless glob '*.jar';
			$need_to_extract{ ( glob '*.jar' )[0] } = __PACKAGE__ . '::extract_jar';
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

	# 5. XXX: Call specific setup for each framework
	#unless ( skip_framework_setup() ) {
		#foreach my $f ( @java_frameworks ) {
			#my $module = "IndieRunner::Java::$f";
			#$module->setup();
		#}
	#}

	$$self{ need_to_extract }	= \%need_to_extract;

	return $self;
}

sub run_cmd ( $self ) {
	my $jar_mode = test_jar_mode();	# if set, run with a game .jar file rather than from extracted files

	# adjust JVM invocation for LWJGL3
	if ( grep { /^\QLWJGL3\E$/ } @java_frameworks ) {
		$java_version{ lwjgl3 } =
			IndieRunner::Java::LWJGL3::get_java_version_preference();
	}

	# expand classpath based on frameworks that are used
	unless ( skip_framework_setup() ) {
		foreach my $fw ( @java_frameworks ) {
			my $module = "IndieRunner::Java::$fw";
			push( @jvm_classpath, $module->add_classpath() );
		}
	}

	# validate java versions
	foreach my $k ( keys %java_version ) {
		if ( grep( /^\Q$java_version{ $k }\E$/, @{$Valid_Java_Versions{$OSNAME}} ) ) {
			$java_version{ $k } = version->declare( $java_version{ $k } );
		}
		else {
			$java_version{ $k } = 0;
		}
	}

	# pick best java version
	my $os_java_version = max( values %java_version );
	$os_java_version = '1.8.0' unless $os_java_version;
	if ( $self->verbose() ) {
		say "Bundled Java version:\t\t" . ( $java_version{ bundled } ?
			$java_version{ bundled } : 'not found' );
		say "LWJGL3 preferred Java version:\t$java_version{ lwjgl3 }"
			if $java_version{ lwjgl3 };
		say "Java version to be used:\t$os_java_version";
	}

	set_java_home( $os_java_version );
	say "Java Home:\t\t\t$java_home" if $self->verbose();
	@jvm_env = ( "JAVA_HOME=" . $java_home, );
	fix_jvm_args();
	push @jvm_args, '-Dorg.lwjgl.system.allocator=system';	# avoids libjemalloc, e.g. Pathway
	push @jvm_args, '-Dorg.lwjgl.util.DebugLoader=true';
	push @jvm_args, '-Dorg.lwjgl.util.Debug=true';
	#push @jvm_args, '-Dos.name=Linux';	# XXX: keep? could cause weird errors

	# more effort to figure out $main_class if not set
	unless ( $main_class ) {
		my @mlines = path( $MANIFEST )->lines_utf8 if -f $MANIFEST;
		map { /^\QMain-Class:\E\s+(\S+)/ and $main_class = $1 } @mlines;
	}

	if ( $jar_mode ) {
		# quirks
		push @jvm_args, '-Dsteam=false' if -f 'Airships';

		return( 'env', @jvm_env, $java_home . '/bin/java', @jvm_args, '-cp',
		        join( ':', @jvm_classpath, '.' ), '-jar', $game_jar );
	}
	else {
		die "Unable to identify main class for JVM execution" unless $main_class;

		return( 'env', @jvm_env, $java_home . '/bin/java', @jvm_args, '-cp',
		        join( ':', @jvm_classpath, '.' ), $main_class );
	}


}

sub post_extract ( $self ) {
	$self->SUPER::post_extract();
	my %bundled_libs = bundled_libraries();
	$$self{ need_to_replace } = \%bundled_libs;
}

1;
