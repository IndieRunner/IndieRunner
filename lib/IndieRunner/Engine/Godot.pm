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

package IndieRunner::Engine::Godot;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use parent 'IndieRunner::Engine';

use Carp;
use IndieRunner::Helpers qw( match_bin_file );

use constant GODOT3_BIN	=>		'/usr/local/bin/godot';
use constant GODOT4_BIN =>		'/usr/local/bin/godot4';
use constant PACK_HEADER_MAGIC =>	'GDPC';

my $game_file;

###
# Godot 4 games for future addition when implemented:
# - Buckshot Roulette (itch.io)
# - 8 Colors Star Guardians (itch.io)
###

sub get_pack_format_version( $file ) {
	my $pack_header_bytes = match_bin_file( 'GDPC.', $file );
	my $pack_format_version = hex unpack( 'H2', substr($pack_header_bytes, -1));
	return $pack_format_version;
}

sub detect_game( $self ) {
	my @pck_files =	glob '*.pck';
	return undef unless @pck_files;
	return $pck_files[0] =~ s/\.pck$//r;
}

sub get_bin( $self ) {
	$game_file = $$self{ id_file } if $$self{ id_file };
	$game_file = ( glob( '*.pck' ) )[0] unless $game_file;
	my $pack_format_version = get_pack_format_version( $game_file );
	if ( $pack_format_version == 1 ) {
		return GODOT3_BIN;
	}
	elsif ( $pack_format_version == 2 ) {
		return GODOT4_BIN;
	}
	else {
		croak "unable to determine Godot binary from $game_file";
	}
}

sub get_args_ref( $self ) {
	my @args = (
		'--quiet',
		'--main-pack',
		$game_file,
		);
	return \@args;
}

1;
