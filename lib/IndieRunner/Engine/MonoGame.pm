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

package IndieRunner::Engine::MonoGame;

=head1 NAME

IndieRunner::Engine::MonoGame - MonoGame engine module

=head1 DESCRIPTION

Module to set up and launch games made with MonoGame.
It inherits from L<IndieRunner::Engine::Mono>.

=over 8

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use parent 'IndieRunner::Engine::Mono';

use Carp;
use Readonly;
use File::Find::Rule;
use autodie;

Readonly my %MG_LIBS => (
	'libSDL2-2.0.so.0'	=> '/usr/local/lib/libSDL2.so.*',
	'liblua53.so'		=> '/usr/local/lib/liblua5.3.so.*',
	'libopenal.so.1'	=> '/usr/local/lib/libopenal.so.*',
	);

=item setup()

Adds insertion of symlinks for certain MonoGame-associated native libraries that are loaded via L<dlopen(3)> (which is why they can't just be added to C<FNA.dll.config>).

=cut

sub setup ( $self ) {
	$self->SUPER::setup();

	# XXX: fold libdl.so.2 into %MG_LIBS
	$$self{ mode_obj }->insert( ( glob( '/usr/lib/libc.so.*' ) )[-1],
	                   'libdl.so.2' );

	foreach my $file ( keys %MG_LIBS ) {
		my @found_files = File::Find::Rule->file
						  ->name( $file )
						  ->maxdepth( 2 )
						  ->in( '.' );
		foreach my $found ( @found_files ) {
			$$self{ mode_obj }->insert( ( glob( $MG_LIBS{ $file } ) )[-1],
			                   $found );
		}
	}
}

1;

=back

=head1 SEE ALSO

L<IndieRunner::Engine::Mono>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
