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

=head1 NAME

IndieRunner::Game - class for game object, to configure game execution

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use Readonly;

=head1 DESCRIPTION

In IndieRunner, the game object is the ultimate arbiter for how a game is run.
It queries the engine object (by reference) for the engine's determination of environment variables, binary, and commandline arguments/flags.
Then it applies any game-specific adjustments, if necessary, and returns the configuration divided into I<env>, I<bin>, and I<args> as a hash.
User-provided arguments to the engine are added to the resuling arguments.

=head1 METHODS

=cut

# lowercase keys for %GAME_ENV and %GAME_ARGS for detection
Readonly my %GAME_ENV => {
	'shenzhen i/o'	=> 'MONO_FORCE_COMPAT=1',
};
Readonly my %GAME_ARGS => {
	'sokosolitaire' => '--video-driver GLES2',	# XXX: may only be needed on Intel GPU
	# TODO: Doors of Trithius needs '-nosteam'
};

=head2 new( { engine = $engine, user_args = $user_args } )

Return a new game object. C<$engine> is a reference to an L<IndieRunner::Engine> object. C<$user_args> is a reference to an array of user-provided arguments to the game's execution, like C<-windowed>, C<-fullscreen>, C<-nosteam> etc..

=cut

sub new ( $class, %init ) {
	my $self = bless { %init }, $class;
	return $self;
}

=head2 engine_config( $engine )

Retrieve binary, environment, and argument configuration from the engine and return it as hash of I<bin>, I<env>, and I<args>.

=cut

sub engine_config ( $engine ) {
	(
	 bin	=> $engine->get_bin(),
	 env	=> $engine->get_env_ref(),	# arrayref
	 args	=> $engine->get_args_ref(),	# arrayref
	);
}

=head2 configure()

Query the engine's configuration, add user arguments, and apply game-specific adjustments to I<env> and I<args>.
Return game configuration (hash with keys I<bin>, I<env>, and I<args>).

=cut

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

__END__

=head1 SEE ALSO

L<IndieRunner>
L<IndieRunner::Engine>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2024 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
