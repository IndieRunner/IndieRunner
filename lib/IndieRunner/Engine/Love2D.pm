# Copyright (c) 2022-2025 Thomas Frohwein
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

package IndieRunner::Engine::Love2D;

=head1 NAME

IndieRunner::Engine::Love2D - Love2D engine module

=head1 DESCRIPTION

Module to set up and launch games made with Love2D.
Currently supports games made with Love2D versions 0.8, 0.9, 0.10, and 11.

=head1 METHODS

=over 8

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use autodie;

use parent 'IndieRunner::Engine';

use File::Find::Rule;
use Readonly;

use IndieRunner::Helpers;

Readonly my %LOVE2D_VERSION_BIN => {
	'0.8.x'		=> 'love-0.8',
	'0.9.x'		=> 'love-0.9',		# not in ports July 2023
	'0.10.x'	=> 'love-0.10',
	'11.x'		=> 'love-11',
	#'12.x'		=> '/nonexistent',	# XXX: need port
	};

Readonly my @LOVE2D_VERSION_FILES => (
	'conf.lua',	# if not packaged, e.g. Move or Die
	'liblove*.so*',
	'love',
	'love.exe',
	'lovec.exe',
	'love.dll',
	'*.exe',
	);

# Quirks to shortcut selecting a specific binary based on presence of a file.
# XXX: need better heuristic for bundled *.love files to not rely on quirks!
Readonly my %LOVE2D_BIN_QUIRKS => {
	'quadrant.love'	=> '11.x',
	};

Readonly my %LOVE2D_GAME_VERSION => {
	'britebot'			=> '0.10.x',
	'cityglitch'			=> '0.10.x',
	'CurseOfTheArrow'		=> '11.x',
	'DepthsOfLimbo'			=> '11.x',
	'hhhs'				=> '11.x', # Hoarder's Horrible House of Stuff
	'LabyrinthOfLegendaryLoot'	=> '11.x',
	'Marvellous_Inc'		=> '0.10.x',
	'Metanet Hunter G4'		=> '11.x',
	'possession'			=> '11.x',
	'soulstice'			=> '0.10.x',
	'SternlyWordedAdventures'	=> '11.x',
	'StoneKingdoms'			=> '11.x',
	};

=item get_bin()

Chooses a Love2D binary.
This is done by examining selected local files for a Love2D version string.

=cut

sub get_bin ( $self ) {
	my @valid_versions = values %LOVE2D_GAME_VERSION;
	# turn @valid_versions into regex
	map { s/x/\\d+/g } @valid_versions;
	map { s/\./\\./g } @valid_versions;

	# quirks
	for my $k ( keys %LOVE2D_BIN_QUIRKS ) {
		if ( -f $k ) {
			return $LOVE2D_VERSION_BIN{ $LOVE2D_BIN_QUIRKS{ $k } };
		}
	}

	my @found;
	for my $g ( @LOVE2D_VERSION_FILES ) {
		push @found, File::Find::Rule->file()
					    ->name( $g )
					    ->in( '.' );
	}
	foreach my $f ( @found ) {
		my $love_v;
		foreach my $v ( @valid_versions ) {
			last if ( $love_v = IndieRunner::Helpers::match_bin_file(
					"$v", $f) );
		}
		next unless $love_v;
		$love_v =~ s/\.\d+$/.x/;
		next unless grep { /^\Q$love_v\E$/ } values %LOVE2D_GAME_VERSION;
		return $LOVE2D_VERSION_BIN{ $love_v };
	}

	die "failed to determine a binary";
}

=item get_args_ref()

Heuristic to identify the actual game file which is then passed as an argument to the binary.

=cut

sub get_args_ref ( $self ) {
	my $game_file;
	my @found = glob( "*.love bin/ArkovsTower bin/snacktorio bin/GravityCircuit bin/EndlessDark bin/love *.exe" );
	for my $f ( @found ) {
		if ( -f $f ) {
			$game_file = $f;
			last;
		}
	}
	die "Failed to identify Love2D game file." unless $game_file;

	return [ $game_file ];
}

1;

__END__

=back

=head1 SEE ALSO

L<IndieRunner::Engine>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
