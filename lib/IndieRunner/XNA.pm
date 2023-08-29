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
use v5.36;

use parent 'IndieRunner::Mono';

use Carp;
use File::Find::Rule;

sub run_cmd ( $self ) {
	return $self->SUPER::run_cmd( );
}

sub new ( $class, %init ) {
	my %need_to_convert;

	my $self = bless {}, $class;
	%$self = ( %$self, %init );

	# TODO: include from IndieRunner::Mono::new()

	# enumerate all WMA and WMV files
	my @wmafiles = File::Find::Rule->file()
					->name( '*.wma' )
					->in( '.' );
	my @wmvfiles = File::Find::Rule->file()
					->name( '*.wmv' )
					->in( '.' );

	foreach my $w ( @wmafiles ) {
		my $ogg = substr( $w, 0, -3 ) . 'ogg';
		if ( not -f $ogg ) {
			$need_to_convert{ $w } = $ogg;
		}
	}
	foreach my $w ( @wmvfiles ) {
		my $ogv = substr( $w, 0, -3 ) . 'ogv';
		if ( not -f $ogv ) {
			$need_to_convert{ $w } = $ogv;
		}
	}

=pod

	if ( scalar( @wmafiles ) + scalar( @wmvfiles ) > 0
		&& ! $self->dryrun() ) {
			say "Converting WMA and WMV media files. "
				. "This may take a few minutes...";
	}

	# convert with ffmpeg
	foreach my $wma ( @wmafiles ) {
		my $ogg = substr( $wma, 0, -3 ) . 'ogg';
		last if ( -f $ogg );
		say "Convert: $wma => $ogg" if ( $self->dryrun() || $self->verbose() );
		unless ( $self->dryrun() ) {
			my @ffmpeg_cmd = ( 'ffmpeg', '-loglevel', 'fatal',
					   '-i', $wma, '-c:a', 'libvorbis',
					   '-q:a', '10', $ogg );
			system( @ffmpeg_cmd ) == 0 or
				croak "system @ffmpeg_cmd failed: $?";
		}
	}
	foreach my $wmv ( @wmvfiles ) {
		my $ogv = substr( $wmv, 0, -3 ) . 'ogv';
		say "Convert: $wmv => $ogv" if ( $self->dryrun() || $self->verbose() );
		unless ( $self->dryrun() ) {
			my @ffmpeg_cmd = ( 'ffmpeg', '-loglevel', 'fatal',
					   '-i', $wmv, '-c:v', 'libtheora',
					   '-q:v', '10', '-c:a', 'libvorbis',
					   '-q:a', '10', $ogv );
			system( @ffmpeg_cmd ) == 0 or
				croak "system @ffmpeg_cmd failed: $?";
		}
	}

=cut

	$$self{ need_to_convert }	= \%need_to_convert;

	return $self;
}

1;
