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

package IndieRunner::Engine;

=head1 NAME

IndieRunner::Engine - supported game engines

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

=head1 DESCRIPTION

B<Warning! Do not use this class directly, as it is a prototype class for specific engines!>

Parent class for specific IndieRunner engine modules. Refer to specific engine modules under L</SEE ALSO>.

=head1 METHODS

=cut

=head2 new()

Create new engine object. Requires an instance of L<IndieRunner::Mode::...> as C<mode_obj> attribute.

=cut

sub new ( $class, %args ) {
	my $self = bless { %args }, $class;
	return $self;
}

=head2 setup()

Perform engine-specific setup operations.

=cut

sub setup ( $self ) {
	$$self{ mode_obj }->vvsay( 'Setup' );

	if ( $$self{ ir_obj }->get_use_rigg ) {
		# check_rigg_binary disables rigg early if no support for engine binary
		$$self{ mode_obj }->check_rigg_binary( $self->get_bin() );
	}
}

=head2 get_bin()

Return the binary to use for the engine.

=cut

sub get_bin( $self ) {
	die "not implemented for $self: " . (caller(0))[3];
}

=head2 get_env_ref()

Return the environment settings for the engine execution.

=cut

sub get_env_ref( $self ) {
	return \@;
}


=head2 get_args_ref()

Return the arguments to the engine for execution.

=cut

sub get_args_ref( $self ) {
	return \@;
}

=head2 set_game_name($name)

Set the game's name, to be used by engine-specific heuristics for how to launch the game.

=cut

sub set_game_name ( $self, $name ) {
	$$self{ game_name } = $name;
}

1;

__END__

=head1 SEE ALSO

L<IndieRunner::Engine::FNA>
L<IndieRunner::Engine::GZDoom>
L<IndieRunner::Engine::Godot>
L<IndieRunner::Engine::HashLink>
L<IndieRunner::Engine::Java>
L<IndieRunner::Engine::Love2D>
L<IndieRunner::Engine::Mono>
L<IndieRunner::Engine::MonoGame>
L<IndieRunner::Engine::ScummVM>
L<IndieRunner::Engine::XNA>
L<IndieRunner::Mode>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2024 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.

=cut
