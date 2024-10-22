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

package IndieRunner::Engine::FNA;
use v5.36;
use version 0.77; our $VERSION = version->declare( 'v0.0.1' );

use parent 'IndieRunner::Engine::Mono';

use Readonly;
use IndieRunner::Engine::Mono;

# $FNA_MIN_VERSION depends on the version of the native support libraries
Readonly my $FNA_MIN_VERSION => version->declare( '21.1' );
Readonly my $FNA_REPLACEMENT => '/usr/local/share/FNA/FNA.dll';

Readonly my $FNA_DLL		=> 'FNA.dll';

# XXX: @ALLOW_BUNDLED_FNA games can't run with rigg at this point and need
#      to be excempted. need a mechanism to pass this on to rigg.
Readonly  my @ALLOW_BUNDLED_FNA => (
	# 'Game.exe',		# game version,		FNA version
	'SuperBernieWorld.exe',	# 1.2.0 (Kitsune Zero)	19.3
	'KitsuneTails.exe',	# 2024-08-01		19.3
	);

sub setup ( $self ) {
	my $skip_fna_version;

	$self->SUPER::setup();

	# check if this is a game where we allow FNA version lower than FNA_MIN_VERSION
	foreach my $f ( glob '*' ) {
		if ( grep( /^\Q$f\E$/, @ALLOW_BUNDLED_FNA ) ) {
			$skip_fna_version = 1;
			last;
		}
	}

	# check if FNA version needs to be replaced
	# XXX: needs re-implementation with rigg
	unless ( $skip_fna_version ) {
		my $fna_bundled_version = version->declare(
			IndieRunner::Engine::Mono::get_assembly_version( $FNA_DLL ) )
			or die "Failed to get version of $FNA_DLL";
		my $fna_replacement_version = '';
		if ( $fna_bundled_version < $FNA_MIN_VERSION ) {
			# check if replacement FNA can be used
			if ( -f $FNA_REPLACEMENT ) {
				$fna_replacement_version =
					version->declare( IndieRunner::Engine::Mono::get_assembly_version( $FNA_REPLACEMENT ) );
			}
			unless ( $fna_replacement_version &&
				$fna_replacement_version >= $FNA_MIN_VERSION ) {
				die "No FNA.dll found with version >= $FNA_MIN_VERSION";
			}
			elsif ( not $self->use_rigg ) {
				$$self{ mode_obj }->insert( $FNA_REPLACEMENT,
				                            $FNA_DLL );
			}
		}
		elsif ( $self->use_rigg ) {
			if ( -l $FNA_DLL ) {
				$$self{ mode_obj }->undo_insert( $FNA_DLL );
			}
		}
	}
}

1;
