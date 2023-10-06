package IndieRunner::Love2D;

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

use parent 'IndieRunner::Engine';

use Readonly;

# TODO: will this hash be used?
Readonly::Hash my %LOVE2D_VERSION_STRINGS => {
	'0.9.x'		=> '0\.9\.[0-9]',
	'0.10.x'	=> '0\.10\.[0-9]',
	'11.x'		=> '11\.[0-9]',
	};

Readonly::Hash my %LOVE2D_VERSION_BIN => {
	'0.8.x'		=> 'love-0.8',
	'0.9.x'		=> 'love-0.9',		# not in ports July 2023
	'0.10.x'	=> 'love-0.10',
	'11.x'		=> 'love-11',
	};

Readonly::Hash my %LOVE2D_GAME_VERSION => {
	'bluerevolver'		=> '0.10.x',
	'cityglitch'		=> '0.10.x',
	'CurseOfTheArrow'	=> '11.x',
	'DepthsOfLimbo'		=> '11.x',
	'GravityCircuit'	=> '11.x',
	'Marvellous_Inc'	=> '0.10.x',
	'Moonring'		=> '11.x',
	'SNKRX'			=> '11.x',
	'Spellrazor'		=> '0.10.x',
	'StoneKingdoms'		=> '11.x',
	'TerraformingEarth'	=> '11.x',
	};

sub get_bin ( $self ) {
	foreach my $k ( keys %LOVE2D_GAME_VERSION ) {
		if ( $$self{ id_file } =~ /$k/ ) {
			return $LOVE2D_VERSION_BIN{ $LOVE2D_GAME_VERSION{ $k } };
		}
	}

	if ( -f 'moonring.exe' ) {
		return $LOVE2D_VERSION_BIN{ $LOVE2D_GAME_VERSION { Moonring } };
	}
	if ( -f 'Spellrazor.exe' ) {
		return $LOVE2D_VERSION_BIN{ $LOVE2D_GAME_VERSION { Spellrazor } };
	}

	# XXX: implement heuristic to get version string from love.exe, lovec.exe
	#      Examples (via `$ strings love.exe`)
	#      - 11.4
	#      - 0.10.1
	#
	#      Regex: maybe '[[:digit:]]{,2}\.[[:digit:]]'

	die "failed to determine a binary";
}

sub get_args_ref ( $self ) {
	my $game_file;

	$game_file = 'moonring.exe' if ( -f 'moonring.exe' );
	$game_file = 'Spellrazor.exe' if ( -f 'Spellrazor.exe' );

	# note: Gravity Circuit => bin/GravityCircuit as argument (is $id_file)
	$game_file = $$self{ id_file } unless $game_file;

	return [ $game_file ];
}

1;
