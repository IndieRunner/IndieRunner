package IndieRunner::Godot;

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

use constant GODOT3_BIN	=> '/usr/local/bin/godot';

sub detect_game ( $self ) {
	my @pck_files =	glob '*.pck';
	return undef unless @pck_files;
	return $pck_files[0] =~ s/\.pck$//r;
}

sub get_bin( $self ) {
	# XXX: will need to disambiguate into Godot3BIN and Godot4BIN eventually
	return GODOT3_BIN;
}

sub get_args_ref( $self ) {
	my @args = (
		'--quiet',
		'--main-pack',
		glob( '*.pck' ),	# XXX: make smarter - -f cli file vs. pck file vs. detected via byte sequence
		);
	return \@args;
}

1;
