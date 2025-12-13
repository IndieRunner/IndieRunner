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

=head1 NAME

IndieRunner::Engine::DosBox - DosBox engine module

=head1 DESCRIPTION

Module to set up and launch DosBox games.

=head1 METHODS

=over 8

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use parent 'IndieRunner::Engine';

use File::Spec::Functions qw( rel2abs );
use JSON;
use Path::Tiny;

# Resources:
# https://www.dosbox.com/wiki/GOG_games_that_use_DOSBox

# XXX: add option for bin/dosbox-x or bin/dosbox; how to choose?
use constant DOSBOX_BIN	=> '/usr/local/bin/dosbox-staging';

=item select_conf_files()

Select bundled DosBox config files that are suitable to be used and return them.

=cut

sub select_conf_files() {
	my @out;
	# XXX: add ->maxdepth( $level )
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
	#XXX: disabled $basic_conf; dosbox-x works better without it
	#push @out, $basic_conf;

	# single_conf is the one ending in _single.conf
	my $single_conf;
	my @all_single_confs = grep { /_single\.conf$/ } @conf_files;
	if ( @all_single_confs ) {
		$single_conf = $all_single_confs[0];
	}
	push( @out, rel2abs( $single_conf ) ) if $single_conf;

	return @out;
}

=item get_bin()

Return the DosBox binary.

=cut

sub get_bin( $self ) { return DOSBOX_BIN; }

=item get_args_ref()

Set up arguments for DosBox execution: config files and parameter to exit after running the command.

=cut

sub get_args_ref( $self ) {
	my @args = ();

	# dosbox-x: disable verbose/unneeded output
	#push @args, '-fastlaunch';	# skip dosbox-x start screen
	# XXX: add switch to enable logging? (mostly useless IMO)
	#push @args, '-nolog';		# disable verbose logging

	for my $c ( select_conf_files() ) {
		push @args, '-conf';
		push @args, $c;
	}

	# XXX: consider using dosbox-x -defaultdir <path> instead of get_exec_dir
	#      or for dosbox-staging: --working-dir <path>

	# XXX: only for dosbox-staging to quit when just leaving menu?
	push @args, '--exit';

	return \@args;
}

=item get_exec_dir()

Heuristic to figure out the working directory from bundled files, if possible.

=cut

sub get_exec_dir( $self ) {
	# GOG DosBox games: check goggame-XXXXXXXXXX.info for "workingDir"
	# XXX: add ->maxdepth( $level )
	# XXX: or use glob instead, like in Helpers.pm?
	my $info_file = File::Find::Rule->file()
					->name( 'goggame-*.info' )
					->start( '.' )
					->match;
	return '' unless $info_file;
	my $dat = decode_json( path( $info_file )->slurp_utf8 ) or return '';

	say $$dat{ playTasks }[0]{ workingDir };
	if ( exists $$dat{ playTasks }[0]{ workingDir } ) {
		return $$dat{ playTasks }[0]{ workingDir };
	}
	return '';
}

1;

__END__

=back

=head1 SEE ALSO

L<IndieRunner::Engine>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2024-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
