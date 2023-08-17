package IndieRunner::Love2D;

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
use autodie;

use parent 'IndieRunner::BaseModule';

use Carp;

use Readonly;

use IndieRunner::Cmdline qw( cli_gameargs cli_verbose );

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
	'SNKRX'			=> '11.x',
	'StoneKingdoms'		=> '11.x',
	'TerraformingEarth'	=> '11.x',
	};

my $bin;

sub get_love_version ( $engine_id_file ) {
	foreach my $k ( keys %LOVE2D_GAME_VERSION ) {
		if ( $engine_id_file =~ /\Q$k\E/ ) {
			IndieRunner::set_game_name( $k );
			return $LOVE2D_GAME_VERSION{ $k };
		}
	}
	confess "failed to identify Love2D game";
}

sub run_cmd ( $, $engine_id_file, $cli_file ) {
	my $verbose = cli_verbose();

	$bin = $LOVE2D_VERSION_BIN{ get_love_version( $engine_id_file ) };
	say "Love2D binary: $bin" if $verbose;

	# NOTE: this is fixed if just installing luasteam.so in lib/lua/5.1/
	# TODO: fix running Terraforming Earth which fails to run with
	#       env LUA_CPATH=/usr/local/lib/luasteam.so:
	#       Error: error loading module 'hump.vector' from file '/usr/local/lib/luasteam.so':
	#               Unable to resolve symbol
	#       This is resolved by using '/usr/local/lib/luasteam.so?', but
	#       I'm not sure about the implications of this.

	# XXX: add arguments from cli_gameargs()

	return ( $bin, $engine_id_file );
}

1;
