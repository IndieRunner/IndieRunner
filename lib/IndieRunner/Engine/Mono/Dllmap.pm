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

package IndieRunner::Engine::Mono::Dllmap;

=head1 NAME

IndieRunner::Engine::Mono::Dllmap - load the dllmap file

=head1 DESCRIPTION

L<mono-config(5)> can remap calls for libraries and specific functions to other libraries and functions. IndieRunner uses a monolithic config file that is loaded to ensure compatibility with a large variety of Mono games.

=over 8

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use Carp;

use File::Share qw( :all );

=item get_dllmap_target()

Returns the path of dllmap.config for Mono engine games.

=cut

sub get_dllmap_target () {
	# XXX: return the user-supplied dllmap file if available, or the one from ShareDir
	# return IndieRunner::Cmdline::cli_dllmap_file() ||
	return dist_file( 'IndieRunner', 'config/dllmap.config' );
}

1;

__END__

=back

=head1 SEE ALSO

L<IndieRunner::Engine::Mono>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
