package IndieRunner::FNA;

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
use v5.10;
use Carp;

use File::Copy qw( copy );
use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::Mono qw( get_assembly_version );

# $FNA_MIN_VERSION depends on the version of the native support libraries
Readonly::Scalar my $FNA_MIN_VERSION => version->parse( '19.2' );
Readonly::Scalar my $FNA_REPLACEMENT => '/usr/local/share/FNA/FNA.dll';

sub run_cmd {
	my ($self, $engine_id_file, $game_file) = @_;
	return IndieRunner::Mono->run_cmd( $game_file );
}

sub setup {
	my ($self) = @_;
	my $dryrun = cli_dryrun();
	my $verbose = cli_verbose();
	my $fna_file = 'FNA.dll';

	IndieRunner::Mono->setup();

	# check if FNA version needs to be replaced
	my $fna_bundled_version = version->parse( get_assembly_version( $fna_file ) )
		or croak "Failed to get version of $fna_file";
	my $fna_replacement_version = '';
	if ( $fna_bundled_version < $FNA_MIN_VERSION ) {
		# check if replacement FNA can be used
		if ( -f $FNA_REPLACEMENT ) {
			$fna_replacement_version =
				version->parse( get_assembly_version( $FNA_REPLACEMENT ) );
		}
		unless ( $fna_replacement_version &&
			$fna_replacement_version >= $FNA_MIN_VERSION ) {
			say "No FNA.dll found with version >= $FNA_MIN_VERSION";
			exit 1;
		}
		else {
			say "Replace: $fna_file $fna_bundled_version " .
				"=> $fna_file $fna_replacement_version"
				if ( $dryrun || $verbose );
			unless ( $dryrun ) {
				unlink $fna_file or croak;
				copy( $FNA_REPLACEMENT, $fna_file )
					or croak "Copy failed: $!";
			}
		}
	}
	else {
		say "FNA.dll version ok: $fna_bundled_version" if $verbose;
	}
}

1;
