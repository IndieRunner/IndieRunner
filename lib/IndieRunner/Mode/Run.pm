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

use parent 'IndieRunner::Mode';

use Cwd;
use OpenBSD::Pledge;
use OpenBSD::Unveil;
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

sub remove( $self, %files ) {
	$self->SUPER::remove( %files );

	my $pid = fork();
	if ( $pid == 0 ) {
		unveil( getcwd(), 'rc' ) || die "unable to unveil: $!";
		pledge( qw( rpath cpath ) ) || die "unable to pledge: $!";
		my $r = unlink( keys %files );
		exit;
	}
	elsif ( not defined( $pid ) ) {
		die "failed to fork: $!";
	}
	waitpid $pid, 0;
}

sub replace( $self, %target_source ) {
	$self->SUPER::replace( %target_source );

	my $pid = fork();
	if ( $pid == 0 ) {
		unveil( getcwd(), 'rc' )	|| die "unable to unveil: $!";
		pledge( qw( rpath cpath ) )	|| die "unable to pledge: $!";
		while ( my ( $target, $source ) = each ( %target_source ) ) {
			if ( -f $target ) {
				my $r = unlink $target || die "$!";
			}
			my $r = symlink $source, $target || die "$!";
		}
		exit;
	}
	elsif ( not defined( $pid ) ) {
		die "failed to fork: $!";
	}
	waitpid $pid, 0;
}

sub convert( $self, %from_to ) {
	$self->SUPER::convert( %from_to );

	my $pid = fork();
	if ( $pid == 0 ) {
		unveil( $WMA_TO_OGG[0], 'x' ) || die "unable to unveil: $!";
		pledge( qw( rpath proc exec ) ) || die "unable to pledge: $!";
		while ( my ( $from, $to ) = each ( %from_to ) ) {
			if ( -e $to ) {
				say STDERR "Error: unable convert because target file $to already exists";
				next;
			}
			if ( $from =~ /.wma$/i ) {
				#my @command = @WMA_TO_OGG =~ s/!<<in>>/$from/r;
				#@command =~ s/!<<out>>/$to/;
				#system( @command ) == 0 || die "Command failed: $command - $!";
			}
			elsif ( $from =~ /.wmv$/i ) {
				my @command = map { s/!<<in>>/$from/r } @WMV_TO_OGV;
				s/!<<out>>/$to/ for @command;
				system( @command ) == 0 || die "Command failed: $!";
			}
			else {
				say "unrecognized extension: $from";
			}
		}
		exit;
	}
	elsif ( not defined( $pid ) ) {
		die "failed to fork: $!";
	}
	waitpid $pid, 0;
}

sub extract( $self, %files_and_subs ) {
	$self->SUPER::extract( %files_and_subs );

	my $pid = fork();
	if ( $pid == 0 ) {
		unveil( $_7Z_COMMAND[0] , 'x' ) || die "unable to unveil: $!";
		pledge( qw( rpath proc exec ) ) || die "unable to pledge: $!";
		while ( my ( $file, $method ) = each ( %files_and_subs ) ) {
			if ( $file =~ /.jar$/i ) {
				system( @_7Z_COMMAND, $file ) == 0 || die "Command failed: $!";
			}
			else {
				say "unrecognized extension: $file";
			}
		}
		exit;
	}
	elsif ( not defined( $pid ) ) {
		die "failed to fork: $!";
	}
	waitpid $pid, 0;
}

sub run( $self, $game_name, %config ) {
	my @full_command = $self->SUPER::run( $game_name, %config );

	unveil( $ENV_CMD, 'x' )		|| die "unable to unveil: $!";
	unveil( $full_command[0], 'x' )	|| die "unable to unveil: $!";
	pledge( qw( rpath exec ) )	|| die "unable to pledge: $!";

	exec( @full_command );
}

1;
