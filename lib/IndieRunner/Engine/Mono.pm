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

package IndieRunner::Engine::Mono;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use parent 'IndieRunner::Engine';

use Carp;
use Readonly;

use IndieRunner::Engine::Mono::Dllmap;
use IndieRunner::Engine::Mono::Iomap;
use IndieRunner::Helpers;
use IndieRunner::IdentifyFiles;

# OpenBSD:	/usr/local/bin/mono
# Gentoo:	/usr/bin/mono
Readonly my $MONO_BIN => 'mono';

Readonly my @MONO_GLOBS => (
	'I18N{,.*}.dll',
	'Microsoft.*.dll',
	'Mono.*.dll',
	'System{,.*}.dll',
	'libMonoPosixHelper.so{,.x86{,_64}}',
	'monoconfig',
	'monomachineconfig',
	'mscorlib.dll',
	);

Readonly my @MONO_GLOB_EXCLUDE => (	# literal (partial) match, not glob or RE
	'System.Data.SQLite.dll',	# SpaceChem
	'System.Data.HashFunction.Core.dll',	# Stardew Valley
	'System.Data.HashFunction.Interfaces.dll',	# Stardew Valley
	'System.Data.HashFunction.xxHash.dll',	# Stardew Valley
	);

Readonly my %QUIRKS_ARGS => {
	'-disableweb'	=> [ 'Hacknet.exe', ],
	'-noSound'	=> [ 'ScourgeBringer.exe', ],
	};

Readonly my %QUIRKS_ENV => {
	'MONO_FORCE_COMPAT=1'	=> [
		'Blueberry.exe',
		'Shenzhen.exe',
		'ThePit.exe',
		],
	};


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

sub get_bin ( $self ) {
	return $MONO_BIN;
}

sub setup ( $self ) {
	# remove system Mono assemblies, except @MONO_GLOB_EXCLUDE
	foreach my $f ( get_mono_files() ) {
		$$self{ mode_obj }->remove( $f )
			unless grep { /\Q$f\E/ } @MONO_GLOB_EXCLUDE;
	}

	# remove config files that do dllmap
	foreach my $c ( glob '*.config' ) {
		$$self{ mode_obj }->remove( $c )
			if ( IndieRunner::Helpers::match_bin_file( 'dllmap', $c ) );
	}

	# replacement for mono's lost MONO_IOMAP
	my %iomaps = IndieRunner::Engine::Mono::Iomap::iomap_symlink();
	while ( ( my $newfile, my $oldfile ) = each ( %iomaps ) ) {
		$$self{ mode_obj }->insert( $oldfile, $newfile );
	}

	# XXX: for 'SSGame.exe': mkdir -p ~/.local/share/SSDD
}


sub get_env_ref ( $self ) {
	my @ld_library_path = (
		'/usr/local/lib',
		'/usr/X11R6/lib',
		'/usr/local/lib/steamworks-nosteam',
		);
	my @mono_path = (
		'/usr/local/share/FNA',
		'/usr/local/lib/steamworks-nosteam',
		);
	my @env = (
		'LD_LIBRARY_PATH='	. join( ':', @ld_library_path ),
		'MONO_CONFIG='		. IndieRunner::Engine::Mono::Dllmap::get_dllmap_target(),
		'MONO_PATH='		. join( ':', @mono_path ),
		'SDL_PLATFORM=Linux',
		);

	# quirks
	foreach my $k ( keys %QUIRKS_ENV ) {
		foreach my $l ( @{ $QUIRKS_ENV{ $k } } ) {
			if ( -e $l ) {
				push @env, $k;
				last;
			}
		}
	}

	return \@env;
}

sub get_args_ref ( $self ) {
	# heuristic to figure out the binary name from game_name
	my @args;
	my $game_file;
	my $first_word = (split( /[[:blank:]]/, $$self{ game_name } ) )[0];
	if ( -f $$self{ game_name } . '.exe' ) {
		$game_file = $$self{ game_name } . '.exe';
	}
	elsif ( -f 'PanzerPaladin.exe' ) {	# XXX: make this process a list
		$game_file = 'PanzerPaladin.exe';
	}
	elsif ( -f ( $$self{ game_name } =~ s/[[:blank:]]//gr ) . '.exe' ) {
		$game_file = ( $$self{ game_name } =~ s/[[:blank:]]//gr ) . '.exe';
	}
	else {
		if ( length( $first_word ) > 3 and my @candidate_files = glob '*' ) {
			if ( @candidate_files = grep { /^\Q$first_word\E.*\.exe$/i }
						@candidate_files ) {
				# heuristic: return shortest file
				my $shortest = $candidate_files[0];
				foreach my $f ( @candidate_files ) {
					$shortest = $f if length( $f ) < length( $shortest );
				}
				$game_file = $shortest;
			}

		}
	}
	($game_file) = glob '*.exe' unless $game_file;	# just pick the first .exe

	confess "Failed to identify game file for Mono, based on detected game name \"$$self{ game_name }\". Aborting." if ( not $game_file );
	push @args, $game_file;

	# quirks
	foreach my $k ( keys %QUIRKS_ARGS ) {
		foreach my $l ( @{ $QUIRKS_ARGS{ $k } } ) {
			if ( -e $l ) {
				push @args, $k;
				last;
			}
		}
	}

	return \@args;
}

1;
