package IndieRunner::IdentifyFiles;

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
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( find_file_magic get_magic_descr );

use Carp;
use File::Find::Rule;
use File::LibMagic;

our %filetypes = (
	'Config'		=> [ '*.config', ],
	'Data'			=> [ '*' ],
	'ManagedEntryPoint'	=> [
					'*.exe',	# e.g. RogueLegacy.exe
					'*boot.dat',	# for hashlink
				   ],
	'ManagedFramework'	=> [
					'FNA.dll',
					'MonoGame.Framework.dll',
				   ],
	'ManagedLibrary'	=> [ '*.dll', ],	# e.g. Steamworks.NET.dll
	'NativeExecutable'	=> [ '*' ],		# e.g. RogueLegacy.bin.x86_64
	'NativeLibrary'		=> [
					'*.so*',	# e.g. libSDL2-2.0.so.0, 
					'*.hdll',	# e.g. openal.hdll
				   ],
);

# get LibMagic description of a file
sub get_magic_descr {
	my $file = shift;
	return File::LibMagic	->new
				->info_from_filename( $file )
				->{description};
}

# go through all files and check for a match
sub find_file_type {
	my $directory	= $_[0];
	my $type	= $_[1];
	my @file_list;
	my @out_list;

	unless (exists($filetypes{$type})) { croak "Error: Invalid filetype"; }

	@file_list = File::Find::Rule->file
				     ->nonempty
				     ->name( $filetypes{$type} )
				     ->in( $directory );
	foreach my $file (@file_list) {
		if ( index( get_magic_descr( $file ),
		     'Mono/.Net assembly' ) > -1 ) {
			push @out_list, $file;
		}
	}
	print join("\n", @out_list) . "\n";
	
	return @out_list;
}

sub find_file_magic {
	my $magic_regex = shift;
	my @files = @_;
	my @out;

	foreach my $f ( @files ) {
		if( grep( /$magic_regex/, get_magic_descr( $f ) ) ) {
			push @out, $f;
		}
	}
	return @out;
}

# equivalent to strings(1)
sub strings {
	open(FH, '<:raw', $_[0])	or croak("Couldn't open file $_[0]: $!");
	local $/ = "\0";
	while (<FH>) {
		while (/([\040-\176\s]{4,})/g) {
			print $1, "\n";
		}
	}
	close(FH);
}

1;
