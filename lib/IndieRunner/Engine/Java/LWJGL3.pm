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

package IndieRunner::Engine::Java::LWJGL3;

=head1 NAME

IndieRunner::Engine::Java::LWJGL3 - module for LWJGL3

=head1 DESCRIPTION

This module assists with setup for Java games that use the LWJGL3 framework.

=over 8

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use English;
use parent 'IndieRunner::Engine::Java::JavaMod';

use Carp qw( cluck );

use base qw( Exporter );
our @EXPORT_OK = qw( get_java_version_preference );

use Readonly;

# if LWJGL3 libs are built with Java 11, they fail to run with 1.8:
# java.lang.NoSuchMethodError: java.nio.ByteBuffer.position(I)Ljava/nio/ByteBuffer;
Readonly my %LWJGL3_JAVA_VERSION => (
	'openbsd'	=> '11',
	);

Readonly my %LWJGL3_DIR => (
	'openbsd'	=> '/usr/local/share/lwjgl3',
	);

=item get_min_java_v()

Return the preferred Java version to use for LWJGL3 games.
This is dependent on the operating system.

=cut

sub get_min_java_v ( $ ) {
	return $LWJGL3_JAVA_VERSION{ $OSNAME };
}

=item add_classpath()

Return the JAR files from the system LWJGL3 directory. 

=cut

sub add_classpath ( $self ) {
	return glob( $LWJGL3_DIR{ $OSNAME } . '/*.jar' );
}

1;

__END__

=back

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 SEE ALSO

L<IndieRunner::Engine::Java::JavaMod>,
L<IndieRunner::Engine::Java::LWJGL2>.

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
