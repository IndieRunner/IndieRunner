package IndieRunner::Mono;

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
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( get_mono_files );

use Carp;
use File::Path qw( make_path );
use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::Mono::Dllmap qw( get_dllmap_target );

Readonly::Scalar our $BIN => 'mono';

Readonly::Array my @MONO_GLOBS => (
	'I18N{,.*}.dll',
	'Microsoft.*.dll',
	'Mono.*.dll',
	'System{,.*}.dll',
	'libMonoPosixHelper.so*',
	'monoconfig',
	'monomachineconfig',
	'mscorlib.dll',
	);

sub get_mono_files {
	my @mono_files;
	my @match;

	foreach my $g ( @MONO_GLOBS ) {
		@match = glob( $g );
		next unless @match;
		if ( -f $match[0] ) {		# check that globbed files exist
			push( @mono_files, @match );
		}
	}

	return @mono_files;
}

sub run_cmd {
	my ($self, $game_file) = @_;

	# TODO: check for quirks: eagle island, MONO_FORCE_COMPAT
	# TODO: setup custom config for MidBoss

	# determine which file is the main assembly for mono
	unless ( $game_file ) {
		my @exe = glob "*.exe";
		if ( scalar @exe > 1 ) {
			say 'More than one .exe file found:';
			say join( ' ', @exe );
			say 'In this case, you must specify the main assembly (for mono)';
			say "Example: $0 [options] $exe[0]";
			exit 1;
		}
		$game_file = $exe[0];
	}

	my @ld_library_path = (
		'/usr/local/lib',
		'/usr/X11R6/lib',
		'/usr/local/lib/steamworks-nosteam',
		);
	my @mono_path = (
		'/usr/local/share/FNA',
		'/usr/local/lib/steamworks-nosteam',
		);
	my @env = (
		'LD_LIBRARY_PATH='	. join( ':', @ld_library_path ),
		'MONO_CONFIG='		. get_dllmap_target(),
		'MONO_PATH='		. join( ':', @mono_path ),
		);

	return ( 'env', @env, $BIN, $game_file );
}

sub setup {
	my ($self) = @_;
	my $dryrun = cli_dryrun;
	my $verbose = cli_verbose;

	# remove system Mono assemblies
	foreach my $f ( get_mono_files ) {
		say "Remove: $f" if ( $dryrun || $verbose );
		unlink $f unless $dryrun;
	}
}

1;
