package IndieRunner::HashLink;

use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use strict;
use warnings;
use v5.10;
use Carp;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );

sub run_cmd {
	my ($self, $engine_id_file, $game_file) = @_;
	croak "Not implemented";
}

sub setup {
        my $dryrun = cli_dryrun;

        foreach my $f ( glob( '*.hdll' ) ) {
                say "Remove: $f" if ( $dryrun || cli_verbose );
                unlink $f unless $dryrun;
        }
}

1;
