package IndieRunner::IdentifyFiles;

use version; our $VERSION = qv('0.0.1');
use strict;
use warnings;
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

# go through all files and check for a match
sub find_file_type {
	my $directory	= $_[0];
	my $type	= $_[1];
	my $file;
	my @file_list;
	my @out_list;

	unless (exists($filetypes{$type})) { croak "Error: Invalid filetype"; }

	@file_list = File::Find::Rule->file
				     ->nonempty
				     ->name( $filetypes{$type} )
				     ->in( $directory );
	foreach $file (@file_list) {
		if ( index( File::LibMagic->new
					  ->info_from_filename( $file )
					  ->{description},
		     'Mono/.Net assembly' ) > -1 ) {
			push @out_list, $file;
		}
	}
	print join("\n", @out_list) . "\n";
	
	return @out_list;
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
__END__

=head1 NAME

=head1 VERSION

=head1 SYNOPSIS
