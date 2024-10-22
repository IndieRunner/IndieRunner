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

=head1 NAME

IndieRunner::Engine::Godot - Godot engine module

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use parent 'IndieRunner::Engine';

use Carp;
use IndieRunner::Helpers qw( match_bin_file );

=head1 DESCRIPTION

Module to set up and launch games made with the Godot game engine.
Currently supports games made with Godot version 3.x or 4.x.

=head2 Status

Workarounds:

=over 8

=item Symlink hack to simulate the use of bundled Godot binary (ARGV0_SYMLINK)

=back

Limitations on OpenBSD include:

=over 8

=item Missing support for some GDNative/GDExtension modules

=item No support for encrypted Godot games

=back

=cut

use constant GODOT3_BIN	=>		'/usr/local/bin/godot';
use constant GODOT4_BIN =>		'/usr/local/bin/godot4';
use constant PACK_HEADER_MAGIC =>	'GDPC';
use constant ARGV0_SYMLINK =>		'.indierunner-godot-helper';

my $game_file;

sub get_pack_format_version() {
	my @files = glob( "*.pck *.x86_64 *.x86 *.exe Melt_Them_All" );
	for my $f ( @files ) {
		# [\x00-\x02] - marker for pack version for Godot 2 (\x00) to
		# Godot 4 (\x02)
		my $pack_header_bytes = match_bin_file( 'GDPC[\x00-\x02]', $f );
		next unless $pack_header_bytes;
		$game_file = $f;
		my $pack_format_version = hex unpack( 'H2', substr($pack_header_bytes, -1));
		return $pack_format_version;
	}
	die "Failed to find pack format version";
}

sub detect_game( $self ) {
	my @pck_files =	glob '*.pck';
	return undef unless @pck_files;
	return $pck_files[0] =~ s/\.pck$//r;
}

sub get_bin( $self ) {
	my $pack_format_version = get_pack_format_version();

	# XXX: create local symlink, fixes issues with binary location (some software like
	#      Crossroad OS expects binary to be in the game dir)

	if ( $pack_format_version == 0 ) {
		die "No runtime for Godot version 2 (pack version 0 in $game_file)";
	}
	elsif ( $pack_format_version == 1 ) {
		$$self{ mode_obj }->insert( GODOT3_BIN, ARGV0_SYMLINK );
	}
	elsif ( $pack_format_version == 2 ) {
		$$self{ mode_obj }->insert( GODOT4_BIN, ARGV0_SYMLINK );
	}
	else {
		croak "unable to determine Godot binary from $game_file";
	}
	return './' . ARGV0_SYMLINK;
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

__END__

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
