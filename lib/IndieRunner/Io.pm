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

package IndieRunner::Io;

=head1 NAME

IndieRunner::Io - filesystem input/output for IndieRunner

=head1 SYNOPSIS

  use IndieRunner::Io;

  write_file($data, $filename);
  read_file($filename);

=head1 DESCRIPTION

General use methods for file input/output operations.

=over 8

=item write_file($data, $filename)

Write $data to $filename. Creates the path if it doesn't already exist. Fails if $filename already exists.

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use autodie;

use File::Path;
use File::Spec::Functions;

sub write_file( $data, $filename ) {
	die "File $filename already exists!" if ( -e $filename );
	my ($vol, $dir, $fil) = File::Spec::Functions::splitpath( $filename );
	File::Path::make_path( File::Spec::Functions::catpath( $vol, $dir ) );

	open( my $fh, '>', $filename );
	print $fh $data;
	close $fh;
}

=item read_file($filename)

Returns data from $filename. Fails if $filename doesn't exist.

=back

=cut

sub read_file( $filename ) {
	my $out;
	die "No such file: $filename" unless ( -f $filename );
	open( my $fh, '<', $filename );
	while( my $line = <$fh> ) {
		$out .= $line;
	}
	close $fh;
	return $out;
}

1;

__END__

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under the ISC license. 
