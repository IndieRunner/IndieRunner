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

package IndieRunner::Engine::Java::LWJGL2;

=head1 NAME

IndieRunner::Engine::Java::LWJGL2 - moddule for LWJGL2

=head1 DESCRIPTION

This module assists with setup for Java games that use the LWJGL2 framework.

=over 8

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use English;
use parent 'IndieRunner::Engine::Java::JavaMod';

use Readonly;

Readonly my %LWJGL2_JAVA_VERSION => (
	'openbsd'	=> '11',
	);

Readonly my %LWJGL2_DIR => (
	        'openbsd'       => '/usr/local/share/lwjgl',
                );

=item get_min_java_v()

Return the preferred Java version to use for LWJGL2 games.
This is dependent on the operating system.

=cut

sub get_min_java_v ( $ ) {
	return $LWJGL2_JAVA_VERSION{ $OSNAME };
}

=item add_classpath()

Return the JAR files from the system LWJGL2 directory.

=cut

sub add_classpath ( $ ) {
	return glob( $LWJGL2_DIR{ $OSNAME } . '/*.jar' );
}

1;

=back

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 SEE ALSO

L<IndieRunner::Engine::Java::JavaMod>,
L<IndieRunner::Engine::Java::LWJGL3>.

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
