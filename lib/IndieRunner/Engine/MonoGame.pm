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

package IndieRunner::Engine::MonoGame;
use v5.36;
use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use parent 'IndieRunner::Engine::Mono';

use Carp;
use Readonly;
use File::Find::Rule;
use autodie;

Readonly my %MG_LIBS => (
	'libSDL2-2.0.so.0'	=> '/usr/local/lib/libSDL2.so.*',
	'liblua53.so'		=> '/usr/local/lib/liblua5.3.so.*',
	'libopenal.so.1'	=> '/usr/local/lib/libopenal.so.*',
	);

sub setup ( $self ) {
	$self->SUPER::setup();

	$$self{ mode_obj }->insert( ( glob( '/usr/lib/libc.so.*' ) )[-1],
	                   'libdl.so.2' );

	foreach my $file ( keys %MG_LIBS ) {
		my @found_files = File::Find::Rule->file
						  ->name( $file )
						  ->maxdepth( 2 )
						  ->in( '.' );
		foreach my $found ( @found_files ) {
			$$self{ mode_obj }->insert( ( glob( $MG_LIBS{ $file } ) )[-1],
			                   $found );
		}
	}
}

1;
