package IndieRunner::Io;

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

use strict;
use warnings;
use v5.32;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use feature qw( signatures );
no warnings qw( experimental::signatures );

use base qw( Exporter );
our @EXPORT_OK = qw( ir_copy ir_symlink neuter script_head write_file );

use autodie;
use Carp;
use File::Copy qw( copy );
use File::Path qw( make_path );
use File::Spec::Functions qw( catpath splitpath );

# XXX: is cli_dryrun needed?
use IndieRunner::Cmdline qw( cli_dryrun cli_mode cli_verbose );
use IndieRunner::Platform qw( get_os );

# beginning of scripts for 'script' mode; e.g. shebang
sub script_head {
	my $os = get_os();
	if ( $os eq 'openbsd' ) {
		say '#!/bin/ksh';
	}
	else {
		confess 'Non-OpenBSD OS not implemented';
	}
}

sub write_file {
	my ($data, $filename) = @_;

	croak "File $filename already exists!" if ( -e $filename );
	my ($vol, $dir, $fil) = splitpath( $filename );
	make_path( catpath( $vol, $dir ) );

	open( my $fh, '>', $filename );
	print $fh $data;
	close $fh;
}

# print OS-specific rename command
sub os_rename( $oldfile, $newfile ) {
	my $os = get_os();
	if ( $os eq 'openbsd' ) {
		say "mv $oldfile $newfile";
	}
	else {
		confess 'Non-OpenBSD OS not implemented';
	}
}

# print OS-specific symlink command
sub os_symlink( $oldfile, $newfile ) {
	my $os = get_os();
	if ( $os eq 'openbsd' ) {
		say "ln -s $oldfile $newfile";
	}
	else {
		confess 'Non-OpenBSD OS not implemented';
	}
}

# print OS-specific symlink command
sub os_copy( $oldfile, $newfile ) {
	my $os = get_os();
	if ( $os eq 'openbsd' ) {
		say "cp $oldfile $newfile";
	}
	else {
		confess 'Non-OpenBSD OS not implemented';
	}
}

# mode-specific rename subroutine
sub _rename( $oldfile, $newfile ) {
	my $mode = cli_mode();
	if ( $mode eq 'run' ) {
		say "Rename: $oldfile => $newfile" if cli_verbose();
		rename $oldfile, $newfile;
	}
	elsif ( $mode eq 'script' ) {
		os_rename( $oldfile, $newfile );
	}
	else {	# mode == 'dryrun'
		say "Rename: $oldfile => $newfile";
	}
}

# mode-specific symlink subroutine
sub _symlink( $oldfile, $newfile ) {
	my $mode = cli_mode();
	if ( $mode eq 'run' ) {
		say "Symlink: $newfile -> $oldfile" if cli_verbose();
		symlink $oldfile, $newfile;
	}
	elsif ( $mode eq 'script' ) {
		os_symlink( $oldfile, $newfile );
	}
	else {	# mode == 'dryrun'
		say "Symlink: $newfile -> $oldfile";
	}
}

# mode-specific symlink subroutine
sub _copy( $oldfile, $newfile ) {
	my $mode = cli_mode();
	if ( $mode eq 'run' ) {
		say "Copy: $oldfile => $newfile" if cli_verbose();
		copy $oldfile, $newfile;
	}
	elsif ( $mode eq 'script' ) {
		os_copy( $oldfile, $newfile );
	}
	else {	# mode == 'dryrun'
		say "Copy: $oldfile => $newfile";
	}
}

# helper function for symlink in IndieRunner
# Syntax: _symlink( string glob_of_oldfile, string newfile, bool overwrite )
sub ir_symlink {
	my ($oldfile_glob, $newfile, $overwrite) = @_;

	my $dryrun = cli_dryrun();
	my $verbose = cli_verbose();
	my @oldfile_array = glob( $oldfile_glob );
	my $oldfile;

	# 3 scenarios: no file, 1 file, more than 1 file
	if ( @oldfile_array == 0 ) {
		return 0;	# no replacement file found
	}
	if ( @oldfile_array == 1 ) {
		$oldfile = $oldfile_array[0];
	}
	elsif ( @oldfile_array < 0 ) {
		confess "scalar should never return < 0";
	}
	else {
		# if file is versioned (e.g. libopenal.so.4.2)
		# last item in array *should* be the highest version
		$oldfile = pop @oldfile_array;
	}

	if ( -e $newfile ) {
		if ( $overwrite ) {
			_rename $newfile, $newfile . '_';
		}
		else {
			return 1 unless cli_mode() eq 'script';
		}
	}

	_symlink($oldfile, $newfile);

	return 1;
}

# helper function to neuter included files by appending '_'
sub neuter( $filename ) {
	_rename( $filename, $filename . '_' ) unless -l $filename;
}

sub ir_copy( $oldfile, $newfile ) {
	_copy( $oldfile, $newfile );
}

1;
