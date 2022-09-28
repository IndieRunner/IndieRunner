package IndieRunner::XNA;

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

use File::Find::Rule;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::Mono;

sub run_cmd {
	my ($self, $engine_id_file, $game_file) = @_;
	# ignoring $engine_id_file for XNA
	return IndieRunner::Mono->run_cmd( $game_file );
}
sub setup {
	my ($self) = @_;
	my $dryrun = cli_dryrun();
	my $verbose = cli_verbose();
	my @wmafiles;
	my @wmvfiles;

	IndieRunner::Mono->setup();

	# convert .wma to .ogg, and .wmv to .ogv

	# enumerate all WMA and WMV files
	my @wmafiles_found = File::Find::Rule->file()
					->name( '*.wma' )
					->in( '.' );
	my @wmvfiles_found = File::Find::Rule->file()
					->name( '*.wmv' )
					->in( '.' );

	# see which WMA and WMV files have OGG/OGV match
	foreach my $w ( @wmafiles_found ) {
		if ( not -f substr( $w, 0, -3 ) . 'ogg' ) {
			push( @wmafiles, $w );
		}
	}
	foreach my $w ( @wmvfiles_found ) {
		if ( not -f substr( $w, 0, -3 ) . 'ogv' ) {
			push( @wmvfiles, $w );
		}
	}

	if ( scalar( @wmafiles ) + scalar( @wmvfiles ) > 0
		&& ! $dryrun ) {
			say "Converting WMA and WMV media files. "
				. "This may take a few minutes...";
	}

	# convert with ffmpeg
	foreach my $wma ( @wmafiles ) {
		my $ogg = substr( $wma, 0, -3 ) . 'ogg';
		last if ( -f $ogg );
		say "Convert: $wma => $ogg" if ( $dryrun || $verbose );
		unless ( $dryrun ) {
			my @ffmpeg_cmd = ( 'ffmpeg', '-loglevel', 'fatal',
					   '-i', $wma, '-c:a', 'libvorbis',
					   '-q:a', '10', $ogg );
			system( @ffmpeg_cmd ) == 0 or
				croak "system @ffmpeg_cmd failed: $?";
		}
	}
	foreach my $wmv ( @wmvfiles ) {
		my $ogv = substr( $wmv, 0, -3 ) . 'ogv';
		say "Convert: $wmv => $ogv" if ( $dryrun || $verbose );
		unless ( $dryrun ) {
			my @ffmpeg_cmd = ( 'ffmpeg', '-loglevel', 'fatal',
					   '-i', $wmv, '-c:v', 'libtheora',
					   '-q:v', '10', '-c:a', 'libvorbis',
					   '-q:a', '10', $ogv );
			system( @ffmpeg_cmd ) == 0 or
				croak "system @ffmpeg_cmd failed: $?";
		}
	}
}

1;
