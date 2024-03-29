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

package IndieRunner::Game;
use strict;
use warnings;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use Readonly;

# lowercase keys for %GAME_ENV and %GAME_ARGS for detection
Readonly::Hash my %GAME_ENV => {
	'shenzhen i/o'	=> 'MONO_FORCE_COMPAT=1',
};
Readonly::Hash my %GAME_ARGS => {
	'sokosolitaire' => '--video-driver GLES2',	# XXX: may only be needed on Intel GPU
};

sub new ( $class, %init ) {
	my $self = bless { %init }, $class;
	return $self;
}

sub engine_config ( $engine ) {
	(
	 bin	=> $engine->get_bin(),
	 env	=> $engine->get_env_ref(),	# arrayref
	 args	=> $engine->get_args_ref(),	# arrayref
	);
}

sub configure ( $self ) {
	%$self = ( %$self, engine_config( $$self{ engine } ) );

	if ( @{ $$self{ user_args } } ) {
		push( @{ $$self{ args } }, @{ $$self{ user_args } } );
	}

	# get game-specific configuration
	unshift( @{ $$self{ env } }, $GAME_ENV{ lc( $$self{ name } ) } || '' );
	unshift( @{ $$self{ args } }, $GAME_ARGS{ lc( $$self{ name } ) } || '' );

	# remove any '' that may have been added above
	@{ $$self{ env } } = grep { !/^$/ } @{ $$self{ env } };
	@{ $$self{ args } } = grep { !/^$/ } @{ $$self{ args } };

	return {
		bin	=> $$self{ bin },
		env	=> $$self{ env },
		args	=> $$self{ args },
	};
}

1;
