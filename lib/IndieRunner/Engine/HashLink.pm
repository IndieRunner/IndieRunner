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

package IndieRunner::Engine::HashLink;
use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use strict;
use warnings;
use v5.36;

use parent 'IndieRunner::Engine';

use Readonly;

Readonly my $HASHLINK_BIN	=> '/usr/local/bin/hl';

# hlboot.dat is fallback inside hl binary
Readonly my @DAT		=> (
					'sdlboot.dat',
					'hlboot-sdl.dat',
					'hlboot.dat',	# XXX: keep? is run by default anyway
					);

sub setup ( $self, $mode_obj ) {
	map { $mode_obj->remove( $_ ) } glob( '*.hdll' );
}

sub get_bin ( $self ) { return $HASHLINK_BIN; }

sub get_args_ref ( $self ) {
	my @args;
	foreach my $d ( @DAT ) {
		if ( -f $d ) {
			push @args, $d;
			last;
		}
	}
	return \@args;
}

1;
