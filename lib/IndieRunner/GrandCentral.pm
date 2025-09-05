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

package IndieRunner::GrandCentral;

=head1 NAME

IndieRunner::GrandCentral - heuristics to determine an IndieRunner game engine

=cut

use v5.36;
use version; our $VERSION = qv('0.0.1');
use autodie;

use Cwd qw( cwd );
use File::Find::Rule;
use Readonly;
use Text::Glob qw( match_glob );

=head1 DESCRIPTION

Heuristic subroutines to analyze files for a match with game engines known to L<IndieRunner>.

=head1 SUBROUTINES

=cut

# SkipFiles are skipped in the heuristic of identify_engine_thorough
Readonly my @SkipFiles => (
	'lovec.exe',
);

Readonly my %Indicator_Files => (
	'FNA.dll'			=> 'FNA',
	'FNA.dll.config'		=> 'FNA',
	'BGMain.exe'			=> 'GemRB',
	'IDMain.exe'			=> 'GemRB',
	'Torment.exe'			=> 'GemRB',
	'*.pck'				=> 'Godot',
	'*.pk3'				=> 'GZDoom',
	'*.ipk3'			=> 'GZDoom',
	'*.hdll'			=> 'HashLink',
	'hlboot.dat'			=> 'HashLink',
	'libhl.*'			=> 'HashLink',
	'detect.hl'			=> 'HashLink',
	'sdlboot.dat'			=> 'HashLink',
	'*.jar'				=> 'Java',
	'jre'				=> 'Java',
	'*lwjgl*.{so,dll}'		=> 'Java',
	'*gdx*.{so,dll}'		=> 'Java',
	'*.love'			=> 'Love2D',
	'MonoGame.Framework.dll'	=> 'MonoGame',
	'MonoGame.Framework.dll.config'	=> 'MonoGame',
	'xnafx40_redist.msi'		=> 'XNA',
	'_CommonRedist/XNA'		=> 'XNA',
	# XXX: implement choosing DosBox only as second line after ScummVM
	'dosbox*_single.conf'		=> 'DosBox',	# GOG DosBox configs
	'__support/app/dosbox*.conf'	=> 'DosBox',	# GOG DosBox configs
);

# combination of file glob and byte sequence to identify frameworks
Readonly my %Indicators => (
	'Godot' => {
		# XXX: find better heuristic for individual files without extension
		#      ('Melt_Them_All')
		'glob'		=> [ '*.x86', '*.x86_64', '*.exe',
				     'Melt_Them_All', ],
		# 'GDPC' is internal byte sequence for the format,
		# but gets false positives
		# alternative: godot_nativescript
		'magic_bytes'	=> 'godot_open',
	},
	'Love2D' => {
		'glob'		=> [	'*.exe',
					'{,bin/}ArkovsTower',
					'{,bin/}EndlessDark',
					'{,bin/}GravityCircuit',
					'{,bin/}snacktorio',
					'bin/love',	# Shell Out Showdown
				   ],
		'magic_bytes'	=> 'love_version',	# or: luaopen_love or love.boot
	},
	'MonoGame' => {
		'glob'		=> [ '*.exe', ],
		'magic_bytes'	=> 'MonoGame.Framework',
	},
	'XNA' => {
		# 'Microsoft.Xna.Framework' is found in XNA, FNA, and MonoGame
		# This needs to be part of a staged heuristic
		'glob'		=> [ '*.exe', ],
		'magic_bytes'	=> 'Microsoft.Xna.Framework',
	},
);

=head2 find_bytes( $file, $bytes )

Scan a file for the (byte)string $bytes.
Returns boolean (1 if found, otherwise 0).

=cut

sub find_bytes ( $file, $bytes ) {
	my $chunksize = 4096;
	my $string;

	open( my $fh, '<:raw', $file );
	# XXX:	works so far, but unclear if this may fail to detect string that
	# 	extends over 2 chunks, unless they are aligned
	while ( read( $fh, $_, $chunksize ) ) {
		# XXX: change to 'if ( $_ eq $bytes )' ??
		if ( /\Q$bytes\E/ ) {
			close $fh;
			return 1;
		}
	}
	close $fh;
	return 0;
}

=head2 identify_engine( $file )

Compare I<filename> against known globs for L<IndieRunner> engines and return the matching engine.
Returns a hash with directory as key and identified engine as value. Set $maxdepth to search subdirectories (C<undef> to not set any maximum depth). Set $all to 1 to not stop after the first match.
Returns an empty hash if no match was found.

=cut

sub identify_engine ( $maxdepth = 0, $all = 0 ) {
	my %ret;

	my $origin = cwd;
	my @subdirs = File::Find::Rule->directory->maxdepth( $maxdepth )->in( '.' );
	for my $s ( @subdirs ) {
		chdir $s or die;
		for my $g ( keys %Indicator_Files ) {
			my @matches = glob( $g . '{,_}' );
			for ( @matches ) {
				# XXX: TOCTOU because of access(2)
				if ( -f $_ ) {
					$ret{ $s } = $Indicator_Files{ $g };
					last; # assumes only 1 engine in a directory
				}
			}
		}
		chdir $origin or die;
		# returning first matched dir unless $all
		last if %ret and not $all;
	}

	return %ret;
}

=head2 identify_engine_thorough( $file )

Compare I<file content> against known bytestrings for L<IndieRunner> engines, using I<find_bytes>.
Returns the matching engine, or an empty hash if no match was found.

=cut

sub identify_engine_thorough ( $maxdepth = 0, $all = 0 ) {
	my %ret;

	my $origin = cwd;
	my @subdirs = File::Find::Rule->directory->maxdepth( $maxdepth )->in( '.' );
	for my $s ( @subdirs ) {
		chdir $s or die;

		for my $engine ( keys %Indicators ) {
			for my $g ( @{ $Indicators{$engine}{glob} } ) {
				my @matches = glob( $g . '{,_}' );
				for my $m ( @matches ) {
					# XXX: TOCTOU because of access(2)
					if ( -f $m and not
					     grep { $_ eq $m } @SkipFiles and
					     find_bytes( $m, $Indicators{$engine}{'magic_bytes'} ) ) {
						$ret{ $s } = $engine;
						last;
					}
				}
				last if %ret;
			}
			last if %ret;
		}
		chdir $origin or die;
		# returning first matched dir unless $all
		last if %ret and not $all;
	}

	return %ret;
}

1;

__END__

=head1 SEE ALSO

L<IndieRunner>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2024 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
