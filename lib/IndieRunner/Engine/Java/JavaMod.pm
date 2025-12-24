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

package IndieRunner::Engine::Java::JavaMod;

=head1 NAME

IndieRunner::Engine::Java::JavaMod - template for modules used by L<IndieRunner::Engine::Java>

=head1 DESCRIPTION

Basic variables and methods for modules used by L<IndieRunner::Engine::Java>.

=over 8

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use autodie;
use English;

use Readonly;

=item add_classpath()

Method for adding to the classpath.
No-op by default.

=cut

sub add_classpath ( $ ) {
	# no-op
}

=item setup($mode_obj)

Setup for the a module used by L<IndieRunner::Engine::Java>.
This is called for each used module from L<IndieRunner::Engine::Java>'s own setup method.
No-op by default.

=cut

sub setup ( $, $mode_obj ) {
	# no-op
}

=item get_min_java()

Returns the minimum required Java version for this specific module (OS-dependent).
Defaults to 0.

=cut

sub get_min_java_v( $ ) {
	return 0;
}

1;

__END__

=back

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 SEE ALSO

L<IndieRunner::Engine::Java>

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
