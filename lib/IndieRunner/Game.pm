package IndieRunner::Game;

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

sub new ( $class, %init ) {
	my $self = bless {}, $class;

	%$self = ( %$self, %init );
	%$self = ( %$self, configure( $$self{ engine } ) );

	return $self;
}

sub configure ( $engine ) {
	my %config = (
		      bin	=> $engine->get_bin(),
		      env	=> $engine->get_env_ref(),	# hashref
		      args	=> $engine->get_args_ref(),	# arrayref
		     );

	# XXX: for development only
	say "bin: $config{ bin }";
	say 'env:';
	while ( my ( $k, $v ) = each ( %{ $config{ env } } ) ) {
		say "$k:\t$v";
	}
	say 'args: ' . join( ' ', @{ $config{ args } } );

	return %config;
}

1;
