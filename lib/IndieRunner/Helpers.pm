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

package IndieRunner::Helpers;

=head1 NAME

IndieRunner::Helpers - helper functions for IndieRunner modules

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use autodie;
use base qw( Exporter );
our @EXPORT_OK = qw ( get_magic_descr goggame_name find_file_magic match_bin_file );

use File::Find::Rule;
use File::LibMagic;
use JSON;
use Path::Tiny;

=head1 DESCRIPTION

Various helper functions used by one or more IndieRunner modules.

=head1 METHODS

=head2 get_magic_descr( $file )

Returns the description of a file, as obtained by L<File::LibMagic>.

=cut

sub get_magic_descr ( $file ) {
	return File::LibMagic	->new
				->info_from_filename( $file )
				->{description};
}

=head2 find_file_magic( $regex, @files )

Search the L<File::LibMagic> description of @files for $regex and return an array of files that match.

=cut

sub find_file_magic ( $magic_regex, @files ) {
	my @out;
	foreach my $f ( @files ) {
		if( grep( /$magic_regex/, get_magic_descr( $f ) ) ) {
			push @out, $f;
		}
	}
	return @out;
}

=head2 match_bin_file( $regex, $file, $case_insensitive )

Perform search for matching regular expression C<$regex> on raw C<$file>.
Returns the matching string, or undef if there is no match.
By default, the match is case-sensitive.
Set $case_insensitive to false (0) to run a case-insensitive match.

=cut

# return first regex match from within a raw file
sub match_bin_file ( $regex, $file, $case_insensitive = 0 ) {
	my $out = $1 if ( $case_insensitive ?
	                  path($file)->slurp_raw =~ /($regex)/i :
	                  path($file)->slurp_raw =~ /($regex)/ );

	# XXX: return empty string '' instead of undef if no match?
	return $out;
}

=head2 goggame_name()

Retrieve game name string from C<goggame-*.info>, a file typically bundled with games distributed by L<https://www.gog.com/>.

=cut

sub goggame_name () {
	my ($info_file) = glob 'goggame-*.info';
	return '' unless $info_file;

	my $dat = decode_json( path( $info_file )->slurp_utf8 ) or return '';
	( exists $$dat{'name'} ) ? return $$dat{'name'} : return '';
}

1;

__END__

=head1 SEE ALSO

L<File::LibMagic>
L<IndieRunner>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2024 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
