use version; our $VERSION = qv('0.0.1');
use strict;
use warnings;
use Carp;

use Readonly;

###
# Module to provide the main functions to pick and choose
# pathway to run the game
###

Readonly::Hash my Indicator_Files => (	# files that are indicative of a framework
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
);

sub identify_native_runtime {
}

1;
__END__

=head1 NAME

=head1 VERSION

=head1 SYNOPSIS
