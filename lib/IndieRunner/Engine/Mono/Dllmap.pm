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

package IndieRunner::Engine::Mono::Dllmap;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use Carp;

use File::Share qw( :all );
use File::Spec::Functions qw( catpath splitpath );	# XXX: remove?
use IndieRunner::Cmdline;

sub get_dllmap_target () {
	#  return the user-supplied dllmap file if available, or the one from ShareDir
	return # IndieRunner::Cmdline::cli_dllmap_file() ||
		dist_file( 'IndieRunner', 'config/dllmap.config' );
}

1;
