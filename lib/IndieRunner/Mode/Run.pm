package IndieRunner::Mode::Run;

# Copyright (c) 2022-2023 Thomas Frohwein
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
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use autodie;
use parent 'IndieRunner::Mode';

use Cwd;
use Readonly;

Readonly my $ENV_CMD => '/usr/bin/env';

Readonly my @WMA_TO_OGG => ( '/usr/local/bin/ffmpeg', '-loglevel', 'fatal', '-i', '!<<in>>', '-c:a', 'libvorbis', '-q:a', '10', '!<<out>>' );
Readonly my @WMV_TO_OGV => ( '/usr/local/bin/ffmpeg', '-loglevel', 'fatal', '-i', '!<<in>>', '-c:v', 'libtheora', '-q:v', '10', '-c:a', 'libvorbis', '-q:a', '10', '!<<out>>' );

# Notes on options for extracting:
# - Archive::Extract fails to fix directory permissions +x (Stardash, INC: The Beginning)
# - jar(1) (JDK 1.8) also fails to fix directory permissions
# - unzip(1) from packages: use -qq to silence and -o to overwrite existing files
#   ... but unzip exits with error about overlapping, possible zip bomb (Space Haven)
# - 7z x -y: verbose output, seems like it can't be quited much (-bd maybe)
Readonly my @_7Z_COMMAND	=> ( '/usr/local/bin/7z', 'x', '-y' );

sub remove( $self, $file ) {
	$self->SUPER::remove( %files );
	rename( $_, $_.'_' );
	return 0;
}

sub replace( $self, $source, $target ) {
	$self->SUPER::replace( %target_source );
	rename $target, $target.'_' if -f $target;
	symlink $source, $target;
	return 0;
}

sub convert( $self, $from, $to ) {
	if ( -e $to ) {
		say STDERR "Error: unable convert - target $to already exists";
		return 1;
	}
	elsif ( $from =~ /.wma$/i ) {
		my @command = map { s/!<<in>>/$from/r } @WMA_TO_OGG;
		@command = map { s/!<<out>>/$to/r } @command;
		system( @command ) == 0 || die "Command failed: $!";
	}
	elsif ( $from =~ /.wmv$/i ) {
		my @command = map { s/!<<in>>/$from/r } @WMV_TO_OGV;
		@command = map { s/!<<out>>/$to/r } @command;
		system( @command ) == 0 || die "Command failed: $!";
	}
	else {
		say "unrecognized extension: $from";
		return 1;
	}
	return 0;
}

sub extract( $self, $file ) {
	$self->SUPER::extract( %files_and_subs );

	if ( $file =~ /.jar$/i ) {
		system( @_7Z_COMMAND, $file ) == 0 || die "system: $!";
	}
	else {
		say "unrecognized extension: $file";
		return 1;
	}
	return 0;
}

sub run( $self, $game_name, %config ) {
	my @full_command = $self->SUPER::run( $game_name, %config );
	system( @full_command );
}

1;
