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

package IndieRunner::Engine::GZDoom;
use strict;
use warnings;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use parent 'IndieRunner::Engine';

use Carp;
use Readonly;

Readonly::Scalar my $GZDOOM_BIN => '/usr/local/bin/gzdoom';
Readonly::Scalar my $GZDOOM_PK3 => '/usr/local/share/games/doom/gzdoom.pk3';

my $game_ipk3_file;

sub setup ( $self, $mode_obj ) {
	# neuter gzdoom.pk3 if present and insert
	# /usr/local/share/games/doom/gzdoom.pk3. Needed for:
	# - Beyond Sunset (demo)
	# - Vomitoreum
	# - I Am Sakuya: Touhou FPS Game

	$mode_obj->insert( $GZDOOM_PK3, 'gzdoom.pk3' );
}

sub detect_game ( $self ) {
	my @ipk3_files = glob '*.ipk3';
	return undef unless @ipk3_files;
	return $game_ipk3_file = ( map { s/\.ipk3$//r } @ipk3_files )[0];
}

sub get_bin ( $self ) {
	return $GZDOOM_BIN;
}

sub get_args_ref( $self ) {
	my @args = (
		'-iwad',
		$game_ipk3_file,
		);
	return \@args;
}

1;
