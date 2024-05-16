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

package IndieRunner::Engine::XNA;
use v5.36;
use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use parent 'IndieRunner::Engine::Mono';

use Carp;
use File::Find::Rule;

sub setup ( $self ) {
	$self->SUPER::setup();

	# enumerate all WMA and WMV files
	my @wmafiles = File::Find::Rule->file()
					->name( '*.wma' )
					->in( '.' );
	my @wmvfiles = File::Find::Rule->file()
					->name( '*.wmv' )
					->in( '.' );

	foreach my $w ( @wmafiles ) {
		my $ogg = substr( $w, 0, -3 ) . 'ogg';
		$$self{ mode_obj }->convert( $w, $ogg );
	}
	foreach my $w ( @wmvfiles ) {
		my $ogv = substr( $w, 0, -3 ) . 'ogv';
		$$self{ mode_obj }->convert( $w, $ogv );
	}
}

1;
