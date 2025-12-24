# Copyright (c) 2022-2025 Thomas Frohwein
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

=head1 NAME

IndieRunner::Engine::Java - Java engine module

=head1 DESCRIPTION

Module to set up and launch games made with Java.
Currently supports games made with Java versions 1.8.0, 11, 17, and 21.

=over 8

=cut

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

use IndieRunner::Helpers qw( get_magic_descr match_bin_file );
use IndieRunner::Engine::Java::LibGDX;
use IndieRunner::Engine::Java::LWJGL2;
use IndieRunner::Engine::Java::LWJGL3;
use IndieRunner::Engine::Java::Steamworks4j;

Readonly my $MANIFEST		=> 'META-INF/MANIFEST.MF';

# Java version string examples: '1.8.0_312-b07'
#                               '1.8.0_181-b02'
#                               '11.0.13+8-1'
#                               '17.0.1+12-1'
#                               '1.7.0-u80-unofficial-b32'
Readonly my $JAVA_VER_REGEX => '\d{1,2}\.\d{1,2}\.\d{1,2}[_\+\-][\w\-]+';

# Quirks for games that need the bundled classes to come first
Readonly my @CLASSPATH_PREFER_BUNDLED	=> ( 'Urtuk: The Desolation', );

Readonly my $So_Sufx => '.so';
my $Bit_Sufx;

Readonly my @LIB_LOCATIONS => (
	'/usr/X11R6/lib',
	'/usr/local/lib',
	# XXX: make lwjgl location conditional; it interferes with e.g. Songs of Syx
	'/usr/local/share/lwjgl',
	);

Readonly my @SKIP_FRAMEWORKS => (
	'TitanAttacks.jar',
	'Airships_sysjava.sh',
	);

Readonly my @JAVA_LINE_PATTERNS => (
	'^java\s',
	'\-Xbootclasspath',
	'\-Djava\.',
	'\s\-cp\s',
	);

Readonly my @INVALID_CONFIG_FILES => (
	'uiskin.json',
	);

Readonly my @EXEC_JAR_FILES => (
	'Airships',
	);

Readonly my @NO_BUNDLED_CONFIG_FILES => (
	'forests_secret*.jar',	# forests_secret_v2_1.jar
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
my $exec_jar;	# run with `-jar <filename>` rather than main_class
my $game_jar;
my $main_class;
my $no_bundled_config;	# don't look for any config before extracting .jar file
my @java_frameworks;
my $java_home;
my @jvm_args;
my @jvm_classpath;
my @jvm_env;

my %java_version = (
	bundled	=> 0,
	lwjgl3	=> 0,
	);

=item fix_jvm_args()

Quirks for certain arguments to the JVM.

=cut

sub fix_jvm_args () {
	my @initial_jvm_args = @jvm_args;

	# replace any '-Djava.library.path=...' with a generic path
	@jvm_args = grep { !/^\-Djava\.library\.path=/ } @initial_jvm_args;
	# have to keep '.' separate from @LIB_LOCATIONS to avoid creating symlink loops
	push @jvm_args, '-Djava.library.path=' . join( ':', @LIB_LOCATIONS, '.' );
}

=item get_bundled_java_version()

Many Java games are distributed with bundled Java files.
In order to match the Java version that the game was created with, get the version number from the bundled files to later pick the right native binary.

=cut

sub get_bundled_java_version () {
	my $bundled_java_bin;

	# find bundled java binary (XXX: alternatively libjava.so or libjvm.so)
	($bundled_java_bin) = (File::Find::Rule->file->name('java')->in('.'),
			       File::Find::Rule->file->name('java.exe')->in('.'),
			       File::Find::Rule->file->name('release')->in('.')
			      );
	return 0 unless $bundled_java_bin;

	# fetch version string and trim to format for JAVA_HOME
	my $got_version = match_bin_file(
						$JAVA_VER_REGEX,
						$bundled_java_bin);
	return 0 unless $got_version;

	if ( $OSNAME eq 'openbsd' ) {
		# OpenBSD: '1.8.0', '11', '17', '21'
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

=item set_java_home($v)

Assign the correct JAVA_HOME based on the version $v.

=cut

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

=item replace_lib($lib)

Returns a system library to serve as a replacement for bundled library $lib.
Returns an empty string if none is found.

=cut

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

=item bundled_libraries()

Identify bundled libraries, then find replacements for them. Returns a hash, containing each bundled library and its replacement.

=cut

sub bundled_libraries () {
	my %symlink_libs;

	# XXX: use '!/' for pointing to path within JAR files
	#      see https://stackoverflow.com/questions/17466261/unable-to-open-resources-in-directories-which-end-with-an-exclamation-mark
	#      jar:<URL for JAR file>!/<path within the JAR file>
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

=item setup()

Setup for Java games: extract JAR file, identify key data like C<main_class>, replace bundled libraries, identify the bundled frameworks (LWJGL2, LWJGL3, LibGDX, ...), and invoke each framework's setup method.

=cut

sub setup ( $self ) {
	# XXX: at present, check_rigg_binary in SUPER::setup needs $java_home
	#      to be set for sub check_bin; warns about uninitialized $java_home
	$self->SUPER::setup();

	# Extract JAR file if not done previously
	unless ( -f $MANIFEST or $exec_jar ) {
		$$self{ mode_obj }->vvsay( "Trying to extract game jar file..." );
		if ( $game_jar ) {
			$$self{ mode_obj }->extract( $game_jar ) || die "failed to extract: $game_jar";
		}
		elsif ( $class_path_ptr ) {
			$$self{ mode_obj }->extract( @{$class_path_ptr}[0] ) || die "failed to extract file";
		}
		else {
			# XXX: review! Needed for Droid Assault, other Puppy Games titles?
			die "No JAR file to extract" unless glob '*.jar';
			foreach my $f ( glob '*.jar' ) {
				$$self{ mode_obj }->extract( $f ) || die "failed to extract: $f";
			}
		}
	}

	# if no java_frameworks, rerun detect_java_frameworks now that jar
	# has been unpacked
	# XXX: find better flow or other way to avoid running this twice in
	#      some circumstances
	detect_java_frameworks() unless @java_frameworks;

	# get main_class from MANIFEST
	if ( -f $MANIFEST and not $main_class ) {
		unless ( $main_class ) {
			my @mlines = path( $MANIFEST )->lines_utf8 if -f $MANIFEST;
			map { /^\QMain-Class:\E\s+(\S+)/ and $main_class = $1 } @mlines;
		}
	}

	# get Java build version number from main_class's file
	if ( $main_class ) {
		my $main_class_file = $main_class;
		$main_class_file =~ tr,.,/,s;
		$main_class_file .= '.class';
		my $mainclass_magic = get_magic_descr( $main_class_file );
		if ( $mainclass_magic =~ /\(Java ([0-9\.\-_\+]+)\)/ ) {
			my $prelim_version = $1;
			for my $v ( @{$Valid_Java_Versions{$OSNAME}} ) {
				if ( rindex( $v, $prelim_version, 0 ) == 0 ) {
					set_java_home( $v );
					last;
				}
			}
		}
	}

	$$self{ mode_obj }->vvsay( "Symlink native system libraries." );
	my %bundled_libs = bundled_libraries();
	foreach my $lib ( keys %bundled_libs ) {
		next unless $bundled_libs{ $lib };
		say "$lib | $bundled_libs{ $lib }";
		$$self{ mode_obj }->insert( $bundled_libs{ $lib }, $lib );
	}

	# Call specific setup for each framework
	unless ( skip_framework_setup() ) {
		foreach my $fw ( @java_frameworks ) {
			my $module = "IndieRunner::Engine::Java::$fw";
			eval "require $module" or die "Failed to load module $module";
			$module->setup( $$self{ mode_obj } );
		}
	}
}

=item has_libgdx()

Look for libgdx in bundled files. Returns 1 if found, 0 if not.

=cut

sub has_libgdx () {
	( glob '*gdx*.{so,dll}' ) ? return 1 : return 0;
}

=item has_steamworks4j()

Look for Steamworks4j in bundled files. Returns 1 if found, 0 if not.

=cut

sub has_steamworks4j () {
	( glob '*steamworks4j*.{so,dll}' ) ? return 1 : return 0;
}

=item has_lwjgl_any()

Look for LWJGL in bundled files. Returns 1 if found, 0 if not.

=cut

sub has_lwjgl_any () {
	if ( File::Find::Rule->file
			     ->name( '*lwjgl*.{so,dll}' )
			     ->in( '.' )
	   ) { return 1; }
	return 0;
}

=item lwjgl_2_or_3()

Return the major version of bundled LWJGL.

=cut

sub lwjgl_2_or_3 () {
	if ( File::Find::Rule->file
			     ->name( '*lwjgl_{opengl,remotery,stb,xxhash}.{so,dll}' )
			     ->in( '.' )
	   ) { return 3; }
	return 2;
}

=item detect_java_frameworks()

Returns an array of the bundled frameworks (LWJGL 2/3, Steamworks4j).

=cut

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

=item skip_framework_setup()

Checks if the game is one where framework setup is disabled.

=cut

sub skip_framework_setup () {
	foreach my $g ( @SKIP_FRAMEWORKS ) {
		return 1 if -e $g;
	}
	return 0;
}

=item test_exec_jar()

Check if the game is one where the JAR is executed directly.

=cut

sub test_exec_jar () {
	foreach my $j ( @EXEC_JAR_FILES ) {
		return 1 if -e $j;
	}
	return 0;
}

=item jar_no_bundled_config()

Check if this is a game that has to run without checking for a bundled config file.

=cut

sub jar_no_bundled_config() {
	foreach my $j ( @NO_BUNDLED_CONFIG_FILES ) {
		while (glob($j)) {
			return $_;
		}
	}
	return undef;
}

=item new($class, %init)

Constructor that detects/sets the following:

=over 8

=item *

$Bit_Sufx

=item *

$exec_jar or $main_class

=item *

$java_version

=item *

$java_home

=item *

$config_file

=item *

$game_jar

=item *

@jvm_args

=item *

@jvm_classpath

=back

It proceeds to extract $game_jar, unless $exec_jar is set.
The data is collected from various bundled files, including bundled shell scripts.

=cut

sub new ( $class, %init ) {
	my $config_file;

	my $self = bless {}, $class;
	%$self = ( %$self, %init );

	die "OS not recognized: " . $OSNAME
		unless ( exists $Valid_Java_Versions{$OSNAME} );

	### SCENARIOS ###
	#
	# 1. jar + config: read config, then unpack .jar, then execute main_class
	#    (Slay the Spire, Urtuk the Desolation)
	# 2. exec_jar game (Airships)
	# 3. no_bundled_config: no config, unpack .jar and determine main_class
	#    from there file (Forest's Secret)
	#
	###  ###

	$exec_jar = test_exec_jar();
	$game_jar = jar_no_bundled_config();
	if ( $game_jar ) {
		$no_bundled_config = 1;
		return $self;
	}

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
	detect_java_frameworks();
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

=item get_bin()

Return the Java binary.

=cut

sub get_bin ( $self ) {
	unless ( $java_home ) {
		return '';
	}
	return $java_home . "/bin/java";
}

=item get_args_ref()

Assembles and returns the arguments to the Java binary.
This involves setting the classpath based on the frameworks that are used, as well as game-specific quirks to the arguments.

=cut

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

	if ( $exec_jar ) {
		push @jvm_args, ( '-cp', join( ':', @jvm_classpath, '.' ) );
		push @jvm_args, ( '-jar', $game_jar );
	}
	else {
		die "Unable to identify main class for JVM execution" unless $main_class;

		my $reverse_classpath = 0;
		for ( @CLASSPATH_PREFER_BUNDLED ) {
			$reverse_classpath = 1 if $$self{ game_name } eq $_;
		}
		if ( $jvm_classpath[0] and $reverse_classpath ) {
			push @jvm_args, ( '-cp', join( ':', '.', @jvm_classpath ) )
		}
		elsif ( $jvm_classpath[0] ) {
			push @jvm_args, ( '-cp', join( ':', @jvm_classpath, '.' ) )
		}
		push @jvm_args, $main_class;
	}

	# quirks
	push @jvm_args, '-Dsteam=false' if -f 'Airships';
	push @jvm_args, '-nosteam' if -f 'DeepestChamber';

	return \@jvm_args;
}

=item get_env_ref()

Returns the array ref for the Java environment variables, i.e. JAVA_HOME.

=cut

sub get_env_ref ( $self ) {
	@jvm_env = ( "JAVA_HOME=" . $java_home, );
	return \@jvm_env;
}

1;

__END__

=back

=head1 CAVEATS

There are many different ways in which Java-based games are distributed and it is impossible to account for all possible variations.
The parsing of files like .config files and especially the shell scripts to obtain the necessary information for execution is a potential source of errors.

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 SEE ALSO

L<IndieRunner::Engine>,
L<IndieRunner::Engine::JavaMod>,
L<IndieRunner::Engine::LWJGL2>,
L<IndieRunner::Engine::LWJGL3>,
L<IndieRunner::Engine::LibGDX>,
L<IndieRunner::Engine::Steamworks4j>.

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
