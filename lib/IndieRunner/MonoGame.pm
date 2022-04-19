package IndieRunner::MonoGame;

use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use strict;
use warnings;
use v5.10;
use Carp;

use IndieRunner::Mono;

sub run_cmd {
	my ($self, $engine_id_file, $game_file) = @_;
	return IndieRunner::Mono::run_cmd( $game_file );
}

sub setup {
	IndieRunner::Mono::setup();
	# XXX
}

1;
