package IndieRunner::MonoGame;

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

use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use strict;
use warnings;
use v5.36;

use parent 'IndieRunner::Mono';

use Carp;
use Readonly;
use File::Find::Rule;
use List::Util qw( maxstr );
use autodie;

use IndieRunner::Io qw( ir_symlink );
use IndieRunner::Mono;

Readonly::Hash my %MG_LIBS => (
	'libSDL2-2.0.so.0'	=> '/usr/local/lib/libSDL2.so.*',
	'libdl.so.2'		=> '/usr/lib/libc.so.*',
	'liblua53.so'		=> '/usr/local/lib/liblua5.3.so.*',
	'libopenal.so.1'	=> '/usr/local/lib/libopenal.so.*',
	);

sub run_cmd ( $self, $engine_id_file, $cli_file ) {
	return $self->SUPER::run_cmd( $cli_file );
}

sub setup ( $self ) {
	$self->SUPER::setup();

	# TODO: combine with IndieRunner::Java::fix_libraries sub

	# create an empty libdl file which will be replaced
	unless ( -e 'libdl.so.2' ) {
		open my $fh, '>', 'libdl.so.2';
		close $fh;
	}

	foreach my $file ( keys %MG_LIBS ) {
		my @found_files = File::Find::Rule->file
						->name( $file )
						->maxdepth( 2 )
						->in( '.' );
		foreach my $found ( @found_files ) {
			# f: regular file test, l: symlink test
			# F L: symlink to existing file => everything ok
			# F l: non-symlink file => needs fixing
			# f L: broken symlink => needs fixing
			# f l: no file found
			my ($f, $l) = ( -f $found , -l $found );
			if ($f and $l) {
				next;
			}
			else {
				ir_symlink( maxstr( glob( $MG_LIBS{$file} ) ), $found, 1 );
			}
		}
	}
}

1;
