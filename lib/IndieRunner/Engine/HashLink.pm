# Copyright (c) 2022-2025 Thomas Frohwein
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

=head1 NAME

IndieRunner::Engine::HashLink - HashLink engine module

=head1 DESCRIPTION

Module to set up and launch games made with HashLink.

=head1 METHODS

=over 8

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use parent 'IndieRunner::Engine';

use Readonly;

Readonly my $HASHLINK_BIN	=> '/usr/local/bin/hl';

# hlboot.dat is fallback inside hl binary
Readonly my @DAT		=> (
					'sdlboot.dat',
					'hlboot-sdl.dat',
					'hlboot.dat',	# XXX: keep? is run by default anyway
					);

=item setup()

Finds and if necessary removes HashLink dynamic libraries.

=cut

sub setup ( $self ) {
	$self->SUPER::setup();

	if ( $self->use_rigg ) {
		map { $$self{ mode_obj }->restore( $_ ) } glob( '*.hdll_' );
	}
	else {
		map { $$self{ mode_obj }->remove( $_ ) } glob( '*.hdll' );
	}
}

=item get_bin()

Return the HashLink binary.

=cut

sub get_bin ( $self ) { return $HASHLINK_BIN; }

=item get_args_ref()

Heuristic to select the main HashLink bytecode file as argument to the binary.

=cut

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

__END__

=back

=head1 SEE ALSO

L<IndieRunner::Engine>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
