package IndieRunner::FindFileType;

use strict;
use warnings;
use version; our $VERSION = qv('0.1.0');

use File::Find::Rule;
use File::LibMagic;

our %filetypes = (	# allowed filetype strings with filename patterns to look at when _fast
	'Config'				=> [ '*.config', ],
	'Data'					=> [ '*' ],				# could be anything
	'ManagedEntryPoint'		=> [
							     '*.exe',			# e.g. RogueLegacy.exe
							     '*boot.dat',		# for hashlink
							   ],
	'ManagedLibrary'		=> [ '*.dll', ],	# e.g. Steamworks.NET.dll
	'NativeExecutable'		=> [ '*' ],			# e.g. RogueLegacy.bin.x86_64
	'NativeLibrary'			=> [
							     '*.so*',		# e.g. libSDL2-2.0.so.0, 
							     '*.hdll',		# e.g. openal.hdll
							   ],
);

# use filename patterns to limit what files to check with LibMagic
sub find_file_type_fast {
	my $directory	= $_[0];
	my $type	= $_[1];
	my @file_list;

	unless (exists($filetypes{$type})) { die "Error: Invalid filetype"; }

	@file_list = File::Find::Rule->file->nonempty->name( $filetypes{$type} )->in( $directory );
	print join("\n", @file_list);

	return @file_list;
}

# go through all files and check with LibMagic for a match
sub find_file_type_thorough {
	my $directory	= $_[0];
	my $type	= $_[1];
	my @file_list;

	@file_list = File::Find::Rule->file->nonempty->in( $directory );
	print join("\n", @file_list);
	

	return @file_list;
}

1;
