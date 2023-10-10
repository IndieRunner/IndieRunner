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

use File::Find::Rule;
use Readonly;

use IndieRunner::Helpers;

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

Readonly::Array my @LOVE2D_VERSION_GLOBS => (
	'conf.lua',	# if not packaged, e.g. Move or Die
	'love',
	'love.exe',
	'lovec.exe',
	'love.dll',
	'*.exe',
	);

Readonly::Hash my %LOVE2D_GAME_VERSION => {
	'cityglitch'			=> '0.10.x',
	'CurseOfTheArrow'		=> '11.x',
	'DepthsOfLimbo'			=> '11.x',
	'Marvellous_Inc'		=> '0.10.x',
	'StoneKingdoms'			=> '11.x',
	'LabyrinthOfLegendaryLoot'	=> '11.x',
	'hhhs'				=> '11.c', # Hoarder's Horrible House of Stuff
	};

Readonly::Array my @QUIRKS_GAMEFILE => (
	'moonring.exe',
	'SNKRX.exe',
	'Spellrazor.exe',
	);

sub get_bin ( $self ) {
	foreach my $k ( keys %LOVE2D_GAME_VERSION ) {
		if ( $$self{ id_file } =~ /$k/ ) {
			return $LOVE2D_VERSION_BIN{ $LOVE2D_GAME_VERSION{ $k } };
		}
	}

	# make a list of regex @valid_versions from the values of %LOVE2D_GAME_VERSION
	my @valid_versions = values %LOVE2D_GAME_VERSION;
	map { s/x/\\d+/g } @valid_versions;
	map { s/\./\\./g } @valid_versions;

	foreach my $g ( @LOVE2D_VERSION_GLOBS ) {
		my @found = File::Find::Rule->file()
					    ->name( $g )
					    ->in( '.' );
		foreach my $f ( @found ) {
			my $love_v;
			foreach my $v ( @valid_versions ) {
				last if ( $love_v = IndieRunner::Helpers::match_bin_file(
						"$v", $f) );
			}
			next unless $love_v;
			$love_v =~ s/\.\d+$/.x/;
			next unless grep { /^\Q$love_v\E$/ } values %LOVE2D_GAME_VERSION;
			return $LOVE2D_VERSION_BIN{ $love_v };
		}
	}

	die "failed to determine a binary";
}

sub get_args_ref ( $self ) {
	my $game_file;

	foreach my $q ( @QUIRKS_GAMEFILE ) {
		$game_file = $q if ( -f $q );
		last if $game_file;
	}

	# note: Gravity Circuit => bin/GravityCircuit as argument (is $id_file)
	$game_file = $$self{ id_file } unless $game_file;

	return [ $game_file ];
}

1;
