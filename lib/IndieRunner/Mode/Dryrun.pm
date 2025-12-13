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

package IndieRunner::Mode::Dryrun;

=head1 NAME

IndieRunner::Mode::Dryrun - dry run mode

=head1 DESCRIPTION

This mode goes through all the steps based on the particular game, without executing any external program or moving any files.

=head1 METHODS

=over 8

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use parent 'IndieRunner::Mode';

# Dryrun only makes sense with verbosity
use constant DRYRUN_MIN_VERBOSITY => 2;

=item new($class, %init)

Special constructor for B<IndieRunner::Mode::Dryrun>.
It sets a minimal verbosity to make the dry run useful.

=cut

sub new ( $class, %init ) {
	$init{ pledge_group } = 'no_file_mod';
	if ( $init{ ir_obj }{ verbosity } < DRYRUN_MIN_VERBOSITY ) {
		$init{ ir_obj }{ verbosity } = DRYRUN_MIN_VERBOSITY;
	}
	return $class->SUPER::new( %init );
}

1;

__END__

=back

=head1 SEE ALSO

L<IndieRunner::Mode>,
L<IndieRunner::Mode::Run>.

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
