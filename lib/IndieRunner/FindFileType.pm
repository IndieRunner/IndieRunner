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
	'ManagedFramework'		=> [
							     'FNA.dll',
							     'MonoGame.Framework.dll',
							   ],
	'ManagedLibrary'		=> [ '*.dll', ],	# e.g. Steamworks.NET.dll
	'NativeExecutable'		=> [ '*' ],			# e.g. RogueLegacy.bin.x86_64
	'NativeLibrary'			=> [
							     '*.so*',		# e.g. libSDL2-2.0.so.0, 
							     '*.hdll',		# e.g. openal.hdll
							   ],
);

# go through all files and check with LibMagic for a match
sub find_file_type {
	my $directory	= $_[0];
	my $type	= $_[1];
	my $fast	= $_[2] || 0;	# 1: speed up by matching filenames
	my @file_list;
	my @out_list;

	unless (exists($filetypes{$type})) { die "Error: Invalid filetype"; }

	if $fast {
		@file_list = File::Find::Rule->file->nonempty->name( $filetypes{$type} )->$in( $directory );
	} else {
		@file_list = File::Find::Rule->file->nonempty->in( $directory );
	}
	foreach my $file (@file_list) {
		#print File::LibMagic->new->info_from_filename( $file )->{description}
		    #. "\n";
		if ( index( File::LibMagic->new->info_from_filename( $file )->{description},
		     'Mono/.Net assembly' ) > -1 ) {
			push @out_list, $file;
		}
	}
	print join("\n", @out_list) . "\n";
	

	return @out_list;
}

1;
