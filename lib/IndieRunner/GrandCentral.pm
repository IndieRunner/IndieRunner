package IndieRunner::GrandCentral;

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
use version; our $VERSION = qv('0.0.1');
use Carp;
use autodie;

use Fcntl qw( SEEK_CUR SEEK_END );
use Readonly;
use Text::Glob qw( match_glob );

###
# Module to provide the main functions to pick and choose
# pathway to run the game
###

Readonly::Hash my %Indicator_Files => (	# files that are indicative of a framework
	# priority files to override regular engine/framework detection
	'steampuppy-public.jar'		=> 'LWJGL',	# Titan Attacks, Ultratron

	# regular engine/framework detection
	'FNA.dll'			=> 'FNA',
	'FNA.dll.config'		=> 'FNA',
	'*.pck'				=> 'Godot',
	'*.hdll'			=> 'HashLink',
	'hlboot.dat'			=> 'HashLink',
	'libhl.so'			=> 'HashLink',
	'libhl.dll'			=> 'HashLink',
	'detect.hl'			=> 'HashLink',
	'sdlboot.dat'			=> 'HashLink',
	'libgdx.so'			=> 'LibGDX',
	'libgdx64.so'			=> 'LibGDX',
	'gdx.dll'			=> 'LibGDX',
	'gdx64.dll'			=> 'LibGDX',
	'desktop-1.0.jar'		=> 'LibGDX',
	'liblwjgl.so'			=> 'LWJGL',
	'liblwjgl64.so'			=> 'LWJGL',
	'lwjgl.dll'			=> 'LWJGL',
	'lwjgl64.dll'			=> 'LWJGL',
	'liblwjgl_opengl.so'		=> 'LWJGL3',
	'liblwjgl_opengl.dylib'		=> 'LWJGL3',
	'lwjgl_opengl.dll'		=> 'LWJGL3',
	'liblwjgl_remotery.so'		=> 'LWJGL3',
	'liblwjgl_stb.so'		=> 'LWJGL3',
	'liblwjgl_xxhash.so'		=> 'LWJGL3',
	'MonoGame.Framework.dll'	=> 'MonoGame',
	'MonoGame.Framework.dll.config'	=> 'MonoGame',
	'xnafx40_redist.msi'		=> 'XNA',
	'_CommonRedist/XNA'		=> 'XNA',	# XXX: check if this is useful at all here
);

Readonly::Hash my %Indicators => (	# byte sequences that are indicative of a framework
	'Godot'	=> {
		'glob'		=> '*.x86_64',
		'magic_bytes'	=> 'GDPC',
	},
	'XNA'	=> {
		# 'Microsoft.Xna.Framework' is found in XNA, FNA, and MonoGame
		# This needs to be part of a staged heuristic
		'glob'		=> '*.exe',
		'magic_bytes'	=> 'Microsoft.Xna.Framework',
	},
	'MonoGame'	=> {
		'glob'		=> '*.exe',
		'magic_bytes'	=> 'MonoGame.Framework',
	},
	'FNA'	=> {
		# likely not specific enough to be reliable
		# alternatively, consider `monodis --assemblyref *.exe | fgrep 'Name=FNA'`
		'glob'		=> '*.exe',
		'magic_bytes'	=> 'FNA',
	},
);

sub find_bytes {
	my ($file, $bytes) = @_;
	my $chunksize = 4096;
	my $string;

	open( my $fh, '<:raw', $file );
	# XXX:	works so far, but unclear if this may fail to detect string that
	# 	extends over 2 chunks
	while ( read( $fh, $_, $chunksize ) ) {
		if ( /\Q$bytes\E/ ) {
			close $fh;
			return 1;
		}
	}
	close $fh;
	return 0;
}

sub identify_engine {
	my $file = shift;

	# standard detection by globbing for keys of %Indicator_Files
	foreach my $engine_pattern ( keys %Indicator_Files ) {
		# account for possible '_' add the end after previous run
		if ( match_glob( $engine_pattern, $file )
		  || match_glob( $engine_pattern . '_', $file ) ) {
			return $Indicator_Files{ $engine_pattern };
		}
	}

	return '';
}

sub identify_engine_thorough {
	my $file = shift;

	# thorough detection via "magic bytes"
	foreach my $engine ( keys %Indicators ) {
		if ( match_glob( $Indicators{$engine}{'glob'}, $file ) and
		     find_bytes( $file, $Indicators{$engine}{'magic_bytes'} )	) {
			return $engine;
		}
	}

	return '';
}

1;
__END__

=head1 NAME

=head1 VERSION

=head1 SYNOPSIS
