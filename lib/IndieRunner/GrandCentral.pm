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

package IndieRunner::GrandCentral;
use v5.36;
use version; our $VERSION = qv('0.0.1');
use autodie;

use Readonly;
use Text::Glob qw( match_glob );

# don't use SkipFiles for identify_engine_thorough
Readonly my @SkipFiles => (
	'lovec.exe',
);

Readonly my %Indicator_Files => (
	'FNA.dll'			=> 'FNA',
	'FNA.dll.config'		=> 'FNA',
	'*.pck'				=> 'Godot',
	'*.pk3'				=> 'GZDoom',
	'*.ipk3'			=> 'GZDoom',
	'*.hdll'			=> 'HashLink',
	'hlboot.dat'			=> 'HashLink',
	'libhl.*'			=> 'HashLink',
	'detect.hl'			=> 'HashLink',
	'sdlboot.dat'			=> 'HashLink',
	'*.jar'				=> 'Java',
	'jre'				=> 'Java',
	'*lwjgl*.{so,dll}'		=> 'Java',
	'*gdx*.{so,dll}'		=> 'Java',
	'*.love'			=> 'Love2D',
	'MonoGame.Framework.dll'	=> 'MonoGame',
	'MonoGame.Framework.dll.config'	=> 'MonoGame',
	'xnafx40_redist.msi'		=> 'XNA',
	'_CommonRedist/XNA'		=> 'XNA',
);

# combination of file glob and byte sequence to identify frameworks
Readonly my %Indicators => (
	'Godot' => {
		'glob'		=> [ '*.x86', '*.x86_64', '*.exe', ],
		# 'GDPC' is internal byte sequence for the format,
		# but gets false positives
		# alternative: godot_nativescript
		'magic_bytes'	=> 'godot_open',
	},
	'Love2D' => {
		'glob'		=> [	'*.exe',
					'{,bin/}snacktorio',
					'{,bin/}GravityCircuit',
					'bin/love',	# Shell Out Showdown
				   ],
		'magic_bytes'	=> 'love_version',	# or: luaopen_love or love.boot
	},
	'MonoGame' => {
		'glob'		=> [ '*.exe', ],
		'magic_bytes'	=> 'MonoGame.Framework',
	},
	'XNA' => {
		# 'Microsoft.Xna.Framework' is found in XNA, FNA, and MonoGame
		# This needs to be part of a staged heuristic
		'glob'		=> [ '*.exe', ],
		'magic_bytes'	=> 'Microsoft.Xna.Framework',
	},
);

sub find_bytes ( $file, $bytes ) {
	my $chunksize = 4096;
	my $string;

	open( my $fh, '<:raw', $file );
	# XXX:	works so far, but unclear if this may fail to detect string that
	# 	extends over 2 chunks, unless they are aligned
	while ( read( $fh, $_, $chunksize ) ) {
		if ( /\Q$bytes\E/ ) {
			close $fh;
			return 1;
		}
	}
	close $fh;
	return 0;
}

sub identify_engine ( $file ) { # detect by globbing for keys of %Indicator_Files
	for my $engine_pattern ( keys %Indicator_Files ) {
		# account for possible '_' add the end after previous run
		if ( match_glob( $engine_pattern, $file )
		  || match_glob( $engine_pattern . '_', $file ) ) {
			return $Indicator_Files{ $engine_pattern };
		}
	}
	return '';
}

sub identify_engine_thorough ( $file ) {
	for my $engine ( keys %Indicators ) {
		if ( #match_glob( $Indicators{$engine}{'glob'}, $file ) and not
		     grep { match_glob( $_, $file ) } @{ $Indicators{$engine}{glob} } and not
		     grep { $_ eq $file } @SkipFiles and
		     find_bytes( $file, $Indicators{$engine}{'magic_bytes'} )	) {
			return $engine;
		}
	}
	return '';
}

1;
