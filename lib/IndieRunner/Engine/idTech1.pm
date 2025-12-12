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

package IndieRunner::Engine::idTech1;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use parent 'IndieRunner::Engine';

use Carp;
use Readonly;

Readonly my $IDTECH1_BIN => '/usr/local/bin/lzdoom';
Readonly my $GZDOOM_PK3_SUBST => '/usr/local/share/games/lzdoom/lzdoom.pk3';

my $game_iwad;

sub setup ( $self ) {
	$self->SUPER::setup();

	# neuter gzdoom.pk3 if present and insert $GZDOOM_PK3_SUBST
	if ( -f 'gzdoom.pk3' ) {
		$$self{ mode_obj }->insert( $GZDOOM_PK3_SUBST, 'gzdoom.pk3' );
	}
}

sub detect_game ( $self ) {
	my @iwad_files = glob '*.ipk3';
	push( @iwad_files, glob '*.wad' );
	push( @iwad_files, glob '*.WAD' );
	return undef unless @iwad_files;

	$game_iwad = $iwad_files[0];
	return $game_iwad =~ s/\.[^\.]+$//r;
}

sub get_bin ( $self ) {
	return $IDTECH1_BIN;
}

sub get_args_ref( $self ) {
	my @args = (
		'-iwad',
		$game_iwad,
		);
	return \@args;
}

1;
