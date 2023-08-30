package IndieRunner::HashLink;

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

use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use strict;
use warnings;
use v5.36;

use parent 'IndieRunner::BaseModule';

use Carp;
use Readonly;

Readonly::Scalar	my $BIN => 'hl';
Readonly::Array		my @DAT => (
					'sdlboot.dat',
					'hlboot-sdl.dat',
					'hlboot.dat',
					);

sub run_cmd ( $self ) {
	foreach my $d ( @DAT ) {
		return ( $BIN, $d ) if ( -f $d );
	}
	croak "Failed to find .dat file for hashlink";
}

sub new ( $class, %init ) {
	my %need_to_remove;
	my $self = bless {}, $class;

	%$self = ( %$self, %init );
	#push @need_to_remove, glob( '*.hdll' );
	foreach my $g ( glob( '*.hdll' ) ) {
		$need_to_remove{ $g } = undef,
	}
	$$self{ need_to_remove }	= \%need_to_remove;

	return $self;
}

1;
