# Copyright (c) 2022-2023 Thomas Frohwein
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
use strict;
use warnings;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use autodie;

use Path::Tiny;

# return first regex match from within a raw file
sub match_bin_file ( $regex, $file, $case_insensitive = 0 ) {
	my $out = $1 if ( $case_insensitive ?
	                  path($file)->slurp_raw =~ /($regex)/i :
	                  path($file)->slurp_raw =~ /($regex)/ );
	return $out;
}

1;
