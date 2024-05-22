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

package IndieRunner::IdentifyFiles;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use base qw( Exporter );
our @EXPORT_OK = qw ( get_magic_descr find_file_magic );

use File::Find::Rule;
use File::LibMagic;

# get LibMagic description of a file
# XXX: fails if there is a broken symlink - add way to handle that or sweep symlinks before this is called
sub get_magic_descr ( $file ) {
	return File::LibMagic	->new
				->info_from_filename( $file )
				->{description};
}

sub find_file_magic ( $magic_regex, @files ) {
	my @out;
	foreach my $f ( @files ) {
		if( grep( /$magic_regex/, get_magic_descr( $f ) ) ) {
			push @out, $f;
		}
	}
	return @out;
}

1;
