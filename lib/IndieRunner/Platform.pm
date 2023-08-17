package IndieRunner::Platform;

# Copyright (c) 2022 Thomas Frohwein
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

use strict;
use warnings;
use v5.036;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use autodie;

use base qw( Exporter );
our @EXPORT_OK = qw( bin_pathcomplete get_os );

use Config;

# return array (or first match) of files in $ENV{'PATH'} that start
# with $fragment. Returns empty array or '' if no match.
# Can also be used as a test if a binary is in path.
sub bin_pathcomplete ( $fragment ) {
	my @matchedfiles;
	my @path = split( /:/, $ENV{'PATH'} );
	while (@path) {
		my $pathdir = shift @path;
		if (-d $pathdir) {
			opendir( my $dh, $pathdir);
			my @candidate_bins = grep { /^\Q$fragment\E/ } readdir( $dh );
			push @matchedfiles, @candidate_bins;
			closedir $dh;
		}
	}
	return wantarray ? @matchedfiles : ( $matchedfiles[0] || '' );
}

sub get_os () {
	return $Config{qw(osname)};
}

1;
