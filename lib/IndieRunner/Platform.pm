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

package IndieRunner::Platform;

=head1 NAME

IndieRunner::Platform - supported platforms

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use English;

=head1 SYNOPSIS

  get_platforms();
  check_platform($name);

=cut

use base qw( Exporter );
our @EXPORT_OK = qw( get_platforms check_platform );

=head1 DESCRIPTION

Supported Platforms:

=over

=item *

OpenBSD

=back

=cut

use Readonly;

Readonly my @Supported_Platforms => (
	'openbsd',
	);

=head1 SUBROUTINES/METHODS

=head2 get_platforms()

  get_platforms();

Return an array of supported platforms.

=cut

sub get_platforms() {
	return @Supported_Platforms;
}

=head2 check_platform( $name )

  check_platform('openbsd');

Check if C<$name> is a supported platform.

=cut

sub check_platform( $name ) {
	if ( grep { fc($_) eq fc($name) } @Supported_Platforms ) {
		return 1;
	}
	return 0;
}

1;

__END__

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2024 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.

=cut
