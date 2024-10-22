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

package IndieRunner::Mode::Run;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

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

# remove doesn't actually delete file, but appends '_'
sub remove( $self, $file ) {
	# rigg hides files using unveil(file, ""), so no need to remove anything
	return 0 if ( -f $file.'_' or -d $file.'_' or $self->use_rigg );
	$self->SUPER::remove( $file );
	return rename( $file, $file.'_' );
}

# restore does the opposite of remove: delete '_' suffix
sub restore( $self, $removed_file ) {
	my $restored_file = $removed_file;
	die "$removed_file doesn't end in '_'" unless chop( $restored_file ) eq '_';
	$self->SUPER::restore( $removed_file );
	return rename( $removed_file, $restored_file );
}

# insert a symlink to $target at $newfile
# dies on error, no return value therefore
sub insert( $self, $target, $newfile ) {
	unless ( symlink( $target, $newfile ) ) {
		my $ret = readlink $newfile;
		unless ( $ret ) {
			# not a symlink; remove existing file
			remove( $self, $newfile ) or unlink $newfile or die;
			symlink( $target, $newfile ) or die;
		}
		elsif ( $ret ne $target ) {
			# symlink is incorrect, so fix it and proceed
			# don't use sub remove here to avoid second symlink
			unlink $newfile or die;
			symlink $target, $newfile or die;
		}
	}
	$self->SUPER::insert( $target, $newfile );
}

# undo_insert does the opposite of insert: removes the symlink and puts old file into place
sub undo_insert( $self, $file ) {
	if ( not -l $file ) {
		die "not a symlink: $file";
	}
	unlink $file or die;
	return restore( $self, $file . '_' );
}

sub convert( $self, $from, $to ) {
	if ( -e $to ) {
		say STDERR "Error: unable convert - target $to already exists";
		return 0;
	}
	$self->SUPER::convert( $from, $to );
	if ( $from =~ /.wma$/i ) {
		my @command = map { s/!<<in>>/$from/r } @WMA_TO_OGG;
		@command = map { s/!<<out>>/$to/r } @command;
		return system( @command ) == 0 || die "Command failed: $!";
	}
	elsif ( $from =~ /.wmv$/i ) {
		my @command = map { s/!<<in>>/$from/r } @WMV_TO_OGV;
		@command = map { s/!<<out>>/$to/r } @command;
		return system( @command ) == 0 || die "Command failed: $!";
	}
	else {
		say STDERR "unrecognized extension: $from - skipping";
		return 0;
	}
}

sub extract( $self, $file ) {
	$self->SUPER::extract( $file );

	if ( $file =~ /.jar$/i ) {
		return system( @_7Z_COMMAND, $file ) == 0 || die "system: $!";
	}
	else {
		say "unrecognized extension: $file";
		return 0;
	}
}

sub run( $self, $game_name, %config ) {
	my @full_command = $self->SUPER::run( $game_name, %config );
	return system( @full_command );
}

1;
