package IndieRunner::Mono;

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( $BIN remove_mono_files run_mono );

use Carp;
use Readonly;

Readonly::Scalar our $BIN => 'mono';

Readonly::Array my @GLOBS2REMOVE => (
	'I18N{,.*}.dll',
	'Microsoft.*.dll',
	'Mono.*.dll',
	'System{,.*}.dll',
	'libMonoPosixHelper.so*',
	'monoconfig',
	'monomachineconfig',
	'mscorlib.dll',
	);

sub remove_mono_files {
	my @files2remove;

	foreach my $g ( @GLOBS2REMOVE ) {
		push( @files2remove, glob( $g ) );
	}
	unlink @files2remove;
}

sub run_mono {
	my $game_file = shift;

	# TODO: check for quirks: eagle island, MONO_FORCE_COMPAT
	# TODO: setup config (symlinks, MidBoss)

	# determine which file is the main assembly for mono
	unless ( $game_file ) {
		my @exe = glob "*.exe";
		if ( scalar @exe > 1 ) {
			say 'More than one .exe file found:';
			say join( ' ', @exe );
			say 'In this case, you must specify the main assembly (for mono)';
			say "Example: $0 [options] $exe[0]";
			exit 1;
		}
		$game_file = $exe[0];
	}

	my @ld_library_path = (
		'/usr/local/lib',
		'/usr/X11R6/lib',
		'/usr/local/lib/steamworks-nosteam',
		);
	my @mono_path = (
		'/usr/local/share/FNA',
		'/usr/local/lib/steamworks-nosteam',
		);
	my @env = (
		'LD_LIBRARY_PATH='	. join( ':', @ld_library_path ),
		'MONO_PATH='		. join( ':', @mono_path ),
		);

	return join( ' ', 'env', @env, $BIN, '"'.$game_file.'"' );
}

1;
