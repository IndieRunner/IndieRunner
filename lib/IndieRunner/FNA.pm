package IndieRunner::FNA;

use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use strict;
use warnings;
use v5.10;
use Carp;

use IndieRunner::Mono qw( $BIN remove_mono_files run_mono );

sub run_cmd {
	my ($self, $engine_id_file, $game_file) = @_;
	return run_mono( $game_file );
}

sub setup {
	remove_mono_files();
	# XXX
}

1;
