package IndieRunner::GrandCentral;

use strict;
use warnings;
use v5.10;
use version; our $VERSION = qv('0.0.1');
use Carp;

use Fcntl qw( SEEK_CUR SEEK_END );
use Readonly;
use Text::Glob qw( match_glob );

###
# Module to provide the main functions to pick and choose
# pathway to run the game
###

Readonly::Hash my %Indicator_Files => (	# files that are indicative of a framework
	'FNA.dll'			=> 'FNA',
	'FNA.dll.config'		=> 'FNA',
	'*.pck'				=> 'Godot',
	'*.hdll'			=> 'HashLink',
	'hlboot.dat'			=> 'HashLink',
	'libhl.so'			=> 'HashLink',
	'libhl.dll'			=> 'HashLink',
	'detect.hl'			=> 'HashLink',
	'libgdx.so'			=> 'LibGDX',
	'libgdx64.so'			=> 'LibGDX',
	'gdx.dll'			=> 'LibGDX',
	'gdx64.dll'			=> 'LibGDX',
	'desktop-1.0.jar'		=> 'LibGDX',
	'liblwjgl.so'			=> 'LWJGL',
	'liblwjgl64.so'			=> 'LWJGL',
	'lwjgl.dll'			=> 'LWJGL',
	'lwjgl64.dll'			=> 'LWJGL',
	'liblwjgl_opengl.so'		=> 'LWJGL3',
	'liblwjgl_opengl.dylib'		=> 'LWJGL3',
	'lwjgl_opengl.dll'		=> 'LWJGL3',
	'liblwjgl_remotery.so'		=> 'LWJGL3',
	'liblwjgl_stb.so'		=> 'LWJGL3',
	'liblwjgl_xxhash.so'		=> 'LWJGL3',
	'MonoGame.Framework.dll'	=> 'MonoGame',
	'MonoGame.Framework.dll.config'	=> 'MonoGame',
	# TODO:	add detection for framework-less games
	#	(Atom Zombie Smasher, Zachtronics games)
	# TODO:	add detection for XNA games
);

Readonly::Hash my %Indicator_Bytes => (	# byte sequences that are indicative of a framework
	'Godot'	=> {
		'glob'	=> '*.x86_64',
		'bytes'	=> 'GDPC',
	},
);

sub find_bytes {
	my ($file, $bytes) = @_;
	my $num_bytes = length( $bytes );
	my $read_bytes;

	open( my $fh, '<:raw', $file ) or croak "Can't open $file";
	while ( sysread( $fh, $read_bytes, $num_bytes ) ) {
		if ( $read_bytes eq $bytes ) {
			return 1;
		}
		sysseek( $fh, 1, SEEK_CUR ) or croak;
	}
	return 0;
}

sub identify_engine {
	my $file = shift;

	foreach my $engine_pattern ( keys %Indicator_Files ) {
		if ( match_glob( $engine_pattern, $file ) ) {
			return $Indicator_Files{ $engine_pattern };
		}
	}

	return '';
}

sub identify_engine_bytes {
	my $file = shift;

	foreach my $engine ( keys %Indicator_Bytes ) {
		if ( match_glob( $Indicator_Bytes{$engine}{'glob'}, $file ) and
		     find_bytes( $file, $Indicator_Bytes{$engine}{'bytes'} )	) {
			return $engine;
		}
	}

	return '';
}

sub identify_native_runtime {
}

1;
__END__

=head1 NAME

=head1 VERSION

=head1 SYNOPSIS
