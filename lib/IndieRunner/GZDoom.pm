package IndieRunner::GZDoom;

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
use Readonly;

use IndieRunner::Io qw( neuter ir_symlink );

Readonly::Scalar my $BIN => 'gzdoom';

sub run_cmd ( $self ) {
	#IndieRunner::set_game_name( ( split /\./, $self->engine_id_file() )[0] );
	$self->game_name( ( split /\./, $self->engine_id_file() )[0] );
	return ( $BIN );
}

sub setup ( $ ) {
	# neuter gzdoom.pk3 if present and replace with symlinked
	# /usr/local/share/games/doom/gzdoom.pk3. Needed for:
	# - Beyond Sunset (demo)
	# - Vomitoreum
	# - I Am Sakuya: Touhou FPS Game
	neuter( 'gzdoom.pk3' ) if -f 'gzdoom.pk3';
	ir_symlink( '/usr/local/share/games/doom/gzdoom.pk3', 'gzdoom.pk3' );
}

1;
