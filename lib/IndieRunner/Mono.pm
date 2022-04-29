package IndieRunner::Mono;

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( get_mono_files );

use Carp;
use File::Path qw( make_path );
use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::Mono::Dllmap qw( get_dllmap_target );

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
	my $verbose = cli_verbose;

	# remove system Mono assemblies
	foreach my $f ( get_mono_files ) {
		say "Remove: $f" if ( $dryrun || $verbose );
		unlink $f unless $dryrun;
	}

	# set up all dllmap's in .config files
	my $dllmap_target = get_dllmap_target;
	my @configs = glob '*.config';
	foreach my $c ( @configs ) {
		my @name_parts = split( /\./, $c );
		next if scalar( @name_parts ) < 3;	# too short, e.g. Xxx.config
		pop @name_parts;
		my $assembly_ext = pop @name_parts;
		my $assembly_name = join( '.', @name_parts);
		my $assembly_config_dir =
			$ENV{'HOME'} .
			'/.mono/assemblies/' .
			$assembly_name . '/';
		my $assembly_config_fullpath = $assembly_config_dir .
			 $assembly_name . '.' . $assembly_ext .
			'.' . 'config';
		unless ( -d $assembly_config_dir ) {
			say "Create: $assembly_config_dir"
				if ( $dryrun || $verbose );
			unless ( $dryrun ) {
				make_path( $assembly_config_dir ) or croak;
			}
		}
		unless ( -e $assembly_config_fullpath ) {
			say "Symlink: $assembly_config_fullpath -> $dllmap_target"
				if ( $dryrun || $verbose );
			unless ( $dryrun ) {
				symlink( $dllmap_target, $assembly_config_fullpath )
					or croak;
			}
		}
	}
}

1;
