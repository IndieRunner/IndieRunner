# Copyright (c) 2022-2024 Thomas Frohwein
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

package IndieRunner::Engine::Java;
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
use Path::Tiny;
use Readonly;

use IndieRunner::Helpers;
use IndieRunner::Engine::Java::LibGDX;
use IndieRunner::Engine::Java::LWJGL2;
use IndieRunner::Engine::Java::LWJGL3;
use IndieRunner::Engine::Java::Steamworks4j;

Readonly::Scalar my $MANIFEST		=> 'META-INF/MANIFEST.MF';

# Java version string examples: '1.8.0_312-b07'
#                               '1.8.0_181-b02'
#                               '11.0.13+8-1'
#                               '17.0.1+12-1'
#                               '1.7.0-u80-unofficial-b32'
Readonly::Scalar my $JAVA_VER_REGEX => '\d{1,2}\.\d{1,2}\.\d{1,2}[_\+\-][\w\-]+';

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
				'21',
			   ],
	);

my $class_path_ptr;
my $game_jar;
my $jar_mode;	# if set, run with a game .jar file rather than from extracted files
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
	($bundled_java_bin) = File::Find::Rule->file->name('java.exe')->in('.')
		unless $bundled_java_bin;
	return undef unless $bundled_java_bin;

	# fetch version string and trim to format for JAVA_HOME
	my $got_version = IndieRunner::Helpers::match_bin_file(
						$JAVA_VER_REGEX,
						$bundled_java_bin);
	return undef unless $got_version;

	if ( $OSNAME eq 'openbsd' ) {
		# OpenBSD: '1.8.0', '11', '17'
		if (substr($got_version, 0, 2) eq '1.') {
			return '1.8.0';
		}
		else {
			return substr( $got_version, 0, 2 );
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

	my @bundled_libs	= File::Find::Rule->file
						  ->name( '*' . $So_Sufx )
						  ->in( '.');

	# ignore anything in jre/
	@bundled_libs	= grep { !/\Qjre\/\E/ } @bundled_libs;

	foreach my $file (@bundled_libs) {
		$symlink_libs{ $file } = replace_lib( $file );
		say "$file | $symlink_libs{ $file }";
	}

	return %symlink_libs;
}

sub setup ( $self ) {
	$self->SUPER::setup();

	# Extract JAR file if not done previously
	unless ( -f $MANIFEST or $jar_mode ) {
		$$self{ mode_obj }->vvsay( "Trying to extract game jar file..." );
		if ( $game_jar ) {
			$$self{ mode_obj }->extract( $game_jar ) || die "failed to extract: $game_jar";
		}
		elsif ( $class_path_ptr ) {
			$$self{ mode_obj }->extract( @{$class_path_ptr}[0] ) || die "failed to extract file";
		}
		else {
			# XXX: review - remove?
			die "No JAR file to extract" unless glob '*.jar';
			#foreach my $f ( glob '*.jar' ) {
				#$$self{ mode_obj }->extract( $f ) || die "failed to extract: $f";
			#}
		}
	}

	$$self{ mode_obj }->vvsay( "Symlink native system libraries." );
	my %bundled_libs = bundled_libraries();
	foreach my $lib ( keys %bundled_libs ) {
		next unless $bundled_libs{ $lib };
		say "$lib | $bundled_libs{ $lib }";
		$$self{ mode_obj }->insert( $bundled_libs{ $lib }, $lib ) || die
			"failed to symlink $lib -> $bundled_libs{ $lib }";
	}

	# Call specific setup for each framework
	detect_java_frameworks();
	unless ( skip_framework_setup() ) {
		foreach my $fw ( @java_frameworks ) {
			my $module = "IndieRunner::Engine::Java::$fw";
			eval "require $module" or die "Failed to load module $module";
			$module->setup( $$self{ mode_obj } );
		}
	}
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

sub detect_java_frameworks () {
	if ( has_libgdx() ) {
		push( @java_frameworks, 'LibGDX' );
		push( @java_frameworks, 'LWJGL' . lwjgl_2_or_3() );	# LibGDX implies LWJGL
	}
	elsif ( has_lwjgl_any() ) {
		push( @java_frameworks, 'LWJGL' . lwjgl_2_or_3() );
	}
	push @java_frameworks, 'Steamworks4j' if has_steamworks4j();
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
	my $config_file;

	my $self = bless {}, $class;
	%$self = ( %$self, %init );

	die "OS not recognized: " . $OSNAME
		unless ( exists $Valid_Java_Versions{$OSNAME} );
	$jar_mode = test_jar_mode();
	$Bit_Sufx = ( $Config{'use64bitint'} ? '64' : '' ) . $So_Sufx;

	$java_version{ bundled } = get_bundled_java_version();
	unless ( $java_version{ bundled } ) {
		say STDERR "Warning: unable to identify Java version from the bundled files.";
	}

	# Get data on main JAR file and more (main class, classpaths, main jar, JVM args)
	# 	a. first check JSON config file
	#	   prioritize *config.json, e.g. for Airships: Conquer the Skies, Lenna's Inception
	#	   commonly config.json, but sometimes e.g. TFD.json
	($config_file) = glob '*config.json';
	($config_file) = glob '*.json' unless $config_file;
	if ( $config_file and ( grep { /^\Q$config_file\E$/ } @INVALID_CONFIG_FILES or ! -e $config_file ) ) {
		undef $config_file;
	}

	if ( $config_file ) {
		$$self{ mode_obj }->vvsay( "Collecting data from config file: $config_file" );
		my $config_data		= decode_json(path($config_file)->slurp_utf8)
			or die "unable to read config data from $config_file: $!";
		$main_class		= $$config_data{'mainClass'}
			or die "Unable to get configuration for mainClass: $!";
		$class_path_ptr = $$config_data{'classPath'} if ( exists($$config_data{'classPath'}) );
		$game_jar = $$config_data{'jar'} if ( exists($$config_data{'jar'}) );
		@jvm_args = @{$$config_data{'vmArgs'}} if ( exists($$config_data{'vmArgs'}) );
	}
	#	b. check shellscripts for the data
	elsif ( my @sh_files = glob '*.sh' ) {
		$$self{ mode_obj }->vvsay( "Looking for configuration data in bundled shell scripts..." );
		#	e.g. Puppy Games LWJGL game, like Titan Attacks, Ultratron (ultratron.sh)
		#	e.g. Delver (run-delver.sh)

		# find and slurp .sh file
		my $content;
		my @lines;
		my @java_lines;
		foreach my $sh ( @sh_files ) {
			$$self{ mode_obj }->vvsay( "Checking $sh ..." );
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
	else {
		$$self{ mode_obj }->vvsay( "No config file or shell script with configuration data found." );
	}

	# set java_home
	if ( grep { /^\QLWJGL3\E$/ } @java_frameworks ) {
		$java_version{ lwjgl3 } =
			IndieRunner::Engine::Java::LWJGL3::get_java_version_preference();
	}

	# validate java versions
	foreach my $k ( keys %java_version ) {
		if ( grep( /^\Q$java_version{ $k }\E$/, @{$Valid_Java_Versions{$OSNAME}} ) ) {
			$java_version{ $k } = version->declare( $java_version{ $k } );
		}
		else {
			# change to next-highest valid Java version
			$java_version{$k} = (sort {$a cmp $b} grep( version->declare($_)->numify
			                                      > version->declare($java_version{$k})->numify,
								@{$Valid_Java_Versions{$OSNAME}} ) )[0];
		}
	}

	# pick best java version
	my $os_java_version = (sort {$b cmp $a} values( %java_version ) )[0];
	$os_java_version = '1.8.0' unless $os_java_version;
	$$self{ mode_obj }->vsay( "Bundled Java version:\t\t" . ( $java_version{ bundled }
		? $java_version{ bundled } : 'not found' ) );
	$$self{ mode_obj }->vsay( "LWJGL3 preferred Java version:\t$java_version{ lwjgl3 }" )
		if $java_version{ lwjgl3 };
	$$self{ mode_obj }->vsay( "Java version to be used:\t$os_java_version" );
	set_java_home( $os_java_version );
	$$self{ mode_obj }->vsay( "Java Home:\t\t\t$java_home" );

	return $self;
}

sub get_bin ( $self ) {
	return $java_home . "/bin/java";
}

sub get_args_ref( $self ) {
	# expand classpath based on frameworks that are used
	unless ( skip_framework_setup() ) {
		foreach my $fw ( @java_frameworks ) {
			my $module = "IndieRunner::Engine::Java::$fw";
			push( @jvm_classpath, $module->add_classpath() );  # XXX: does this work at all?
		}
	}

	fix_jvm_args();
	push @jvm_args, '-Dorg.lwjgl.system.allocator=system';	# avoids libjemalloc, e.g. Pathway
	push @jvm_args, '-Dorg.lwjgl.util.DebugLoader=true';
	push @jvm_args, '-Dorg.lwjgl.util.Debug=true';
	#push @jvm_args, '-Dos.name=Linux';	# XXX: keep? could cause weird errors

	if ( $jar_mode ) {
		push @jvm_args, ( '-cp', join( ':', @jvm_classpath, '.' ) );
		push @jvm_args, ( '-jar', $game_jar );
	}
	else {
		die "Unable to identify main class for JVM execution" unless $main_class;
		push @jvm_args, ( '-cp', join( ':', '.', @jvm_classpath ) ) if $jvm_classpath[0];
		push @jvm_args, $main_class;
	}

	# quirks
	push @jvm_args, '-Dsteam=false' if -f 'Airships';
	push @jvm_args, '-nosteam' if -f 'DeepestChamber';

	return \@jvm_args;
}

sub get_env_ref ( $self ) {
	@jvm_env = ( "JAVA_HOME=" . $java_home, );
	# more effort to figure out $main_class if not set
	unless ( $main_class ) {
		my @mlines = path( $MANIFEST )->lines_utf8 if -f $MANIFEST;
		map { /^\QMain-Class:\E\s+(\S+)/ and $main_class = $1 } @mlines;
	}
	return \@jvm_env;
}

1;
