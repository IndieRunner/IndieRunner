# Copyright (c) 2024-2025 Thomas Frohwein
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

package IndieRunner::Engine::DosBox;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use parent 'IndieRunner::Engine';

# Resources:
# https://www.dosbox.com/wiki/GOG_games_that_use_DOSBox

# XXX: add option for bin/dosbox-x
use constant DOSBOX_BIN	=> '/usr/local/bin/dosbox';

sub select_conf_files() {
	my @out;
	my @conf_files = File::Find::Rule->file()
					 ->name( 'dosbox*.conf' )
					 ->in( '.' );

	return (undef) unless @conf_files;

	# pick only 2 conf files: $basic_conf and $single_conf
	# basic_conf is the one with the shortest name
	my $basic_conf = $conf_files[0];
	for( @conf_files ) {
		$basic_conf = $_ if length( $_ ) < length( $basic_conf );
	}
	push @out, $basic_conf;

	# single_conf is the one ending in _single.conf
	my $single_conf;
	my @all_single_confs = grep { /_single\.conf$/ } @conf_files;
	if ( @all_single_confs ) {
		$single_conf = $all_single_confs[0];
	}
	push( @out, $single_conf ) if $single_conf;

	return @out;
}

sub get_bin( $self ) { return DOSBOX_BIN; }

sub get_args_ref( $self ) {
	my @args = ();
	for my $c ( select_conf_files() ) {
		push @args, '-conf';
		push @args, $c;
	}
	return \@args;
}

1;
