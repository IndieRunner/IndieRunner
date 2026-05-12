# Copyright (c) 2026 Thomas Frohwein
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

package IndieRunner::Engine::FileExtCustom;

=head1 NAME

IndieRunner::Engine::FileExtCustom- engine module for simple file extension associations

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use parent 'IndieRunner::Engine';

use autodie;

my $bin;
my $conf = '/tmp/indierunner-custom.conf';	# XXX: Readonly? Choose file location?
my $gamefile;	# XXX: Readonly?
my %ext_to_bin;	# file extension to binary

=head1 DESCRIPTION

Module to launch games based on their file extensions, based on (customizable) lists.

=over 8

=item parse_file()

Parse the file with extension - binary associations.

=cut

sub parse_file( $file ) {
	open my $fh, '<', $file;
	# XXX: add a way to skip comment lines /^\s*#/
	%ext_to_bin = map { split /\s+/; } <$fh>;
	close $fh;
}

=item setup()

Read the file with the extension - binary assocations.

=cut

sub setup ( $self ) {
	$self->SUPER::setup();

	# read the extensions-binaries from file into hash
	parse_file( $conf );

	# XXX: allow for the specific file to be passed as IndieRunner CLI argument
	#      instead of this heuristic.
	for my ( $k, $v ) ( %ext_to_bin ) {
		my @matches = glob(qq("*.${k}"));
		if ( @matches ) {
			# XXX: current heuristic: pick first match
			$gamefile = $matches[0];
			$bin = $v;
			last;
		}
	}

	die "Could not set up Engine " . __PACKAGE__ . ". No match." unless $bin;
}

=item get_bin()

Return the binary chosen based on the file extension.

=cut

sub get_bin( $self ) {
	return $bin;
}

=item get_args_ref()

Return arguments for execution (the game file).

=back

=cut

sub get_args_ref( $self ) {
	# XXX
	my @args = ( $gamefile );
	return \@args;
}

1;

__END__

=head1 SEE ALSO

L<IndieRunner::Engine>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2026 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
