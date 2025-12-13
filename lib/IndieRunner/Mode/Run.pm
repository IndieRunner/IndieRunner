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

package IndieRunner::Mode::Run;

=head1 NAME

IndieRunner::Mode::Run - mode to run the game

=head1 DESCRIPTION

This mode is used by default and executes everything needed to run the game, if it can.

=head1 METHODS

=over 8

=cut

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

=item remove($file)

Remove file by actually renaming it so that it is not found by the game binary anymore.
This is done by appending "_" to the filename.
No action if this has already been done before or if L<rigg(1)> is used.

=cut

sub remove( $self, $file ) {
	# rigg hides files using unveil(file, ""), so no need to remove anything
	return 0 if $self->use_rigg;
	# balk if $file.'_' exists because rename(2) would clobber it and we
	# don't want that
	return 0 if -e $file.'_';

	$self->SUPER::remove( $file );
	return rename( $file, $file.'_' );
}

=item restore($removed_file)

Reverses the L</remove($file)> operation by renaming the file back to it's original name.

=cut

sub restore( $self, $removed_file ) {
	my $restored_file = $removed_file;
	die "$removed_file doesn't end in '_'" unless chop( $restored_file ) eq '_';
	$self->SUPER::restore( $removed_file );
	return rename( $removed_file, $restored_file );
}

=item insert($target, $newfile)

Insert a symlink to C<$target> as C<$newfile>.
Dies on error; therefore no return value.

=cut

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

=item undo_insert($file)

Remove the symlink and restore the original file.
This reverses L</insert($target, $newfile)>.

=cut

# undo_insert does the opposite of insert: removes the symlink and puts old file into place
sub undo_insert( $self, $file ) {
	if ( not -l $file ) {
		die "not a symlink: $file";
	}
	unlink $file or die;
	return restore( $self, $file . '_' );
}

=item convert($from, $to)

Convert from one file type to another.
This is generally for multimedia files and the conversion procedure is determined by the file extension.
Recognized file formats are: WMA, WMV.

=cut

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

=item extract($file)

Extract a file. At this point only for JAR files and uses 7-zip for this.

=cut

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

=item run($game_name, %config)

Execute the run command which is built from the configuration %config.
See L<IndieRunner::Mode> for details.

=cut

sub run( $self, $game_name, %config ) {
	my @full_command = $self->SUPER::run( $game_name, %config );
	if ( $config{ exec_dir } ) {
		chdir $config{ exec_dir } or die "chdir failed: $config{ exec_dir }" ;
	}
	return system( @full_command );
}

1;

__END__

=back

=head1 SEE ALSO

L<IndieRunner::Mode>,
L<IndieRunner::Mode::Dryrun>,
L<IndieRunner::Mode::Script>.

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
