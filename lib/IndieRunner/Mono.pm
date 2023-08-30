package IndieRunner::Mono;

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
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use parent 'IndieRunner::BaseModule';

use Carp;
use File::Path qw( make_path );
use Readonly;

use IndieRunner::IdentifyFiles;
use IndieRunner::Mono::Dllmap qw( get_dllmap_target );
use IndieRunner::Mono::Iomap;

Readonly::Scalar my $BIN => 'mono';

Readonly::Array my @MONO_GLOBS => (
	'I18N{,.*}.dll',
	'Microsoft.*.dll',
	'Mono.*.dll',
	'System{,.*}.dll',
	'libMonoPosixHelper.so{,.x86{,_64}}',
	'monoconfig',
	'monomachineconfig',
	'mscorlib.dll',
	);

Readonly::Array my @MONO_GLOB_EXCLUDE => (	# regexes
	'^System\.Data\.SQLite\.dll$',	# SpaceChem
	);

Readonly::Hash my %QUIRKS_ARGS => {
	'-disableweb'	=> [ 'Hacknet.exe', ],
	'-noSound'	=> [ 'ScourgeBringer.exe', ],
	};

Readonly::Hash my %QUIRKS_ENV => {
	'MONO_FORCE_COMPAT=1'	=> [
		'Blueberry.exe',
		'Shenzhen.exe',
		'ThePit.exe',
		],
	};

my @cil_args;
my @env;

sub get_mono_files ( $custom_suffix = '' ) {
	my @mono_files;
	my @match;

	foreach my $g ( @MONO_GLOBS ) {
		@match = glob( $g . $custom_suffix );	# $custom_suffix: e.g. '_'
		next unless @match;

		if ( -f $match[0] ) {		# check that globbed files exist
			push( @mono_files, @match );
		}
	}

	return @mono_files;
}

sub get_assembly_version ( $assembly_file ) {
        my $monodis_info = qx( monodis --assembly $assembly_file );
        if ( $monodis_info =~ /\nVersion:\s+([0-9\.]+)/ ) {
	        return $1;
        }
        else {
		return '';
        }
}

sub quirks ( $game_file ) {
	foreach my $k ( keys %QUIRKS_ARGS ) {
		if ( grep { $_ eq $game_file } @{ $QUIRKS_ARGS{ $k } } ) {
			push @cil_args, $k;
		}
	}
	foreach my $k ( keys %QUIRKS_ENV ) {
		if ( grep { $_ eq $game_file } @{ $QUIRKS_ENV{ $k } } ) {
			push @env, $k;
		}
	}
	# XXX: for 'SSGame.exe': mkdir -p ~/.local/share/SSDD
}

sub run_cmd ( $self ) {
	# TODO: check for quirks: eagle island, MONO_FORCE_COMPAT
	# TODO: setup custom config for MidBoss

	# determine which file is the main assembly for mono

	my @exe = glob "*.exe";
	my @cil;
	my $game_file;

	# XXX: add check for IndieRunner{ file } for command-line supplied file
	foreach my $e ( @exe ) {
		if ( index( IndieRunner::IdenfityFiles::get_magic_descr( $e ),
			'Mono/.Net assembly' ) > -1 ) {
				push @cil, $e;
		}
	}

	if ( scalar @cil > 1 ) {
		say "\nMore than one CIL .exe file found:";
		say "\n\t" . join( "\n\t", @cil ) . "\n";
		say "In this case, you must specify the main mono assembly.\n";
		say "Example:\n$0 -f \"$cil[0]\"\n";
		exit 1;
	}
	$game_file = $cil[0];

	IndieRunner::set_game_name( (split /\./, $game_file)[0] );

	my @ld_library_path = (
		'/usr/local/lib',
		'/usr/X11R6/lib',
		'/usr/local/lib/steamworks-nosteam',
		);
	my @mono_path = (
		'/usr/local/share/FNA',
		'/usr/local/lib/steamworks-nosteam',
		);
	@env = (
		'LD_LIBRARY_PATH='	. join( ':', @ld_library_path ),
		'MONO_CONFIG='		. get_dllmap_target(),
		'MONO_PATH='		. join( ':', @mono_path ),
		'SDL_PLATFORM=Linux',
		);
	quirks $game_file;

	return ( 'env', @env, $BIN, $game_file, @cil_args );
}

sub new ( $class, %init ) {
	my @need_to_remove;

	my $self = bless {}, $class;
	%$self = ( %$self, %init );

	# neuter system Mono assemblies, except @MONO_GLOB_EXCLUDE
	push @need_to_remove, get_mono_files();
	foreach my $e ( @MONO_GLOB_EXCLUDE ) {
		@need_to_remove = grep { !/$e/ } @need_to_remove;
	}

	# replacement for mono's lost MONO_IOMAP
	my %need_to_replace = IndieRunner::Mono::Iomap::iomap_symlink();

	$$self{ need_to_remove }	= \@need_to_remove;
	$$self{ need_to_replace }	= \%need_to_replace;

	return $self;
}

1;
