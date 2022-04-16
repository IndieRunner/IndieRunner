package IndieRunner::Godot;

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use Carp;
use Readonly;

Readonly::Scalar my $BIN => 'godot';

sub run_cmd {
	my ($self, $game_file) = @_;

	my $main_pack = "--main-pack \"$game_file\"";

	return join(' ', $BIN, $main_pack);
}

sub setup {
	# No setup needed.
}

1;
