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
use v5.36;

use parent 'IndieRunner::Mono';

use Carp;
use Readonly;

use IndieRunner::Io qw( ir_copy neuter );
use IndieRunner::Mono qw( get_assembly_version );

# $FNA_MIN_VERSION depends on the version of the native support libraries
Readonly::Scalar my $FNA_MIN_VERSION => version->declare( '21.1' );
Readonly::Scalar my $FNA_REPLACEMENT => '/usr/local/share/FNA/FNA.dll';

Readonly::Array  my @ALLOW_BUNDLED_FNA => (
	# 'Game.exe',		# game version,		FNA version
	'SuperBernieWorld.exe',	# 1.2.0 (Kitsune Zero),	19.3
	);

sub run_cmd ( $self ) {
	return $self->SUPER::run_cmd();
}

sub new ( $class ) {
	# XXX: make this class less verbose (say)
	my @neuter_files;
	my %symlink_files;
	my $fna_file = 'FNA.dll';
	my $fna_config_file = 'FNA.dll.config';
	my $skip_fna_version;

	# check if this is a game where we allow FNA version lower than FNA_MIN_VERSION
	foreach my $f ( glob '*' ) {
		if ( grep( /^\Q$f\E$/, @ALLOW_BUNDLED_FNA ) ) {
			$skip_fna_version = 1;
			last;
		}
	}

	# check if FNA version needs to be replaced
	unless ( $skip_fna_version ) {
		my $fna_bundled_version = version->declare(
			get_assembly_version( $fna_file ) )
			or croak "Failed to get version of $fna_file";
		my $fna_replacement_version = '';
		if ( $fna_bundled_version < $FNA_MIN_VERSION ) {
			# check if replacement FNA can be used
			if ( -f $FNA_REPLACEMENT ) {
				$fna_replacement_version =
					version->declare( get_assembly_version( $FNA_REPLACEMENT ) );
			}
			unless ( $fna_replacement_version &&
				$fna_replacement_version >= $FNA_MIN_VERSION ) {
				say "No FNA.dll found with version >= $FNA_MIN_VERSION";
				exit 1;
			}
			else {
				$symlink_files{ $fna_file } = $FNA_REPLACEMENT;
			}
		}
		else {
			say "FNA.dll version ok: $fna_bundled_version";
		}
	}
	push( @neuter_files, $fna_config_file ) if ( -f $fna_config_file );

	return bless {
		neuter_files => \@neuter_files,
		symlink_files	=> \%symlink_files,
	}, $class;
}

1;
