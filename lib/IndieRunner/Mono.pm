package IndieRunner::Mono;

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( get_mono_files );

use Carp;
use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );

Readonly::Scalar our $BIN => 'mono';

Readonly::Array my @MONO_GLOBS => (
	'I18N{,.*}.dll',
	'Microsoft.*.dll',
	'Mono.*.dll',
	'System{,.*}.dll',
	'libMonoPosixHelper.so*',
	'monoconfig',
	'monomachineconfig',
	'mscorlib.dll',
	);

sub get_mono_files {
	my @mono_files;
	my @match;

	foreach my $g ( @MONO_GLOBS ) {
		@match = glob( $g );
		next unless @match;
		if ( -f $match[0] ) {		# check that globbed files exist
			push( @mono_files, @match );
		}
	}

	return @mono_files;
}

sub run_cmd {
	my ($self, $game_file) = @_;

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

sub setup {
	my $dryrun = cli_dryrun;

	foreach my $f ( get_mono_files ) {
		say "Remove: $f" if ( $dryrun || cli_verbose );
		unlink $f unless $dryrun;
	}
}

1;
