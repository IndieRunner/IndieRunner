package IndieRunner::FNA;

use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use strict;
use warnings;
use v5.10;
use Carp;

use IndieRunner::Mono qw( $BIN remove_mono_files );

sub run_cmd {
	my ($self, $game_file) = @_;

	# TODO: check for quirks: eagle island, multiple .exe, MONO_FORCE_COMPAT
	# TODO: setup config (symlinks, MidBoss)
	# TODO: evaluate FNA.dll; check if need to remove/replace

	my @exe = glob "*.exe";
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

	say join( ' ', 'env', @env, $BIN, '"'.$exe[0].'"' );
	exit;
	return join( ' ', 'env', @env, $BIN, '"'.$exe[0].'"' );
}

sub setup {
	remove_mono_files();
	# XXX
}

1;
