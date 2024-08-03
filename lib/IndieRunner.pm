# Copyright (c) 2022-2024 Thomas Frohwein
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package IndieRunner;

=head1 NAME

IndieRunner - Launch your indie games on more platforms

=head1 SYNOPSIS

 use IndieRunner;

 # create IndieRunner object with default values
 chdir path/to/game or die "chdir failed: $!";
 my $indierunner = IndieRunner->new();

 # perform setup of files for the project
 $indierunner->setup();

 # run the project
 $indierunner->run();

=head1 DESCRIPTION

B<IndieRunner> handles the nitty gritty details of running a variety of (indie) games made with certain engines (SEE ALSO).
It performs heuristics to determine type of engine, setup needs, and runtime configuration.
Modes for dryrun and the generation of a statical shell script that can be used independently of IndieRunner are included.

=head1 METHODS

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.2');
use English;

use Carp;
use File::Find::Rule;
use File::Share qw( :all );
use File::Spec::Functions qw( splitpath );
use Readonly;

use IndieRunner::Engine;
use IndieRunner::Engine::Mono;		# for get_mono_files
use IndieRunner::Engine::ScummVM;	# for detect_game during engine heuristic
use IndieRunner::Game;
use IndieRunner::GrandCentral;
use IndieRunner::Helpers qw( find_file_magic goggame_name );
use IndieRunner::Io;

use constant {
	RIGG_NONE	=> 0,
	RIGG_PERMISSIVE	=> 1,
	RIGG_STRICT	=> 2,
	RIGG_DEFAULT	=> 3,
};

# keep this in sync with return of IndieRunner::Cmdline::init_cli()
Readonly my %INIT_DEFAULTS => {
	dllmap		=> '',
	dryrun		=> undef,
	engine		=> undef,
	file		=> '',
	game		=> '',
	game_args	=> undef,
	use_rigg	=> RIGG_DEFAULT,
	script		=> undef,
	verbosity	=> 0,
};

=head2 get_use_rigg()

Return the value of use_rigg: 0 = disabled, 1 = permissive, 2 = strict, 3 = default.

=cut

sub get_use_rigg( $self ) {
	return $$self{ use_rigg };
}

=head2 set_use_rigg( $rigg_mode )

Set the value of use_rigg: 0 = disable, 1 = permissive, 2 = strict, 3 = default.
This determines if rigg will be used (if supported).
I<default> converts to I<strict>, unless the game is listed in @NoStrict or @NoRigg (see L<IndieRunner::Mode>).

=cut

sub set_use_rigg( $self, $rigg_mode ) {
	if ( $rigg_mode < RIGG_NONE or $rigg_mode > RIGG_DEFAULT ) {
		croak "tried to set invalid rigg mode: $rigg_mode";
	}
	$$self{ use_rigg } = $rigg_mode;
}

=head2 new()

Constructor.

=cut

sub new ( $class, %init ) {
	my $self = bless {}, $class;

	my $engine;
	my $engine_id_file;

	# set attributes from %init or default
	while ( my ( $k, $v ) = each ( %INIT_DEFAULTS ) ) {
		$$self{ $k } = defined( $init{ $k } ) ? $init{ $k } : $v;
	}

	# determine and set mode (Run, Dryrun, or Script)
	my $mode = __PACKAGE__ . '::Mode::' . ( $init{ script } ? 'Script' : ( $init{ dryrun } ? 'Dryrun' : 'Run' ) );
	eval "require $mode" or die "Failed to load module $mode: $@";
	$$self{ mode } = $mode->new(
		# ir_obj: IndieRunner object for referencing verbosity, use_rigg
		ir_obj		=> $self,
	);
	$$self{ mode }->vvsay( 'Mode: ' . (split( '::', $mode))[-1] );

	# detect and load engine
	unless ( $engine = $init{ engine } ) {
		( $engine, $engine_id_file ) = ( detect_engine( $self ) );
	}
	my $engine_class = __PACKAGE__ . '::Engine::' . $engine;
	$$self{ mode }->vvsay( 'Engine: ' . (split( '::', $engine_class))[-1] );
	eval "require $engine_class" or die "Failed to load module $engine_class: $@";
	$$self{ engine } = $engine_class->new(
		# ir_obj: IndieRunner object for referencing verbosity, use_rigg
		ir_obj		=> $self,
		id_file		=> $engine_id_file || '',
		mode_obj	=> $$self{ mode },
	);

	# set game from cli argument if present
	my $game_name = $init{ game } || detect_game_name( $$self{ engine } );
	$$self{ mode }->vvsay( 'Game Name: ' . $game_name );

	if ( $$self{ use_rigg } == RIGG_DEFAULT ) {
		$$self{ mode }->resolve_rigg_default( $game_name );
	}

	$$self{ engine }->set_game_name( $game_name );

	$$self{ game } = ( __PACKAGE__ . '::Game' )->new(
		name		=> $game_name,
		engine		=> $$self{ engine },
		user_args	=> @$self{ game_args },
	);

	return $self;
}

sub detect_engine ( $self ) {
	my $engine;
	my $engine_id_file;

	# XXX: move the file search and iteration into identify_engine()
	my @files = File::Find::Rule->file()->maxdepth( 3 )->in( '.' );

	# 1st Pass: File Names
	$$self{ mode }->vvsay( 'Engine detection: 1st pass' );
	foreach my $f ( @files ) {
		# use just basename of file, as different games put those files
		# in different directories
		my $basename = (splitpath( $f ))[2];
		$engine = IndieRunner::GrandCentral::identify_engine($basename);
		if ( $engine ) {
			$engine_id_file = $f;
			last;
		}
	}
	return ( $engine, $engine_id_file || '' ) if $engine;

	# not FNA, XNA, or MonoGame on 1st pass; check if it could still be Mono
	$engine = 'Mono' if IndieRunner::Engine::Mono::get_mono_files() or
		IndieRunner::Engine::Mono::get_mono_files('_');
	return ( $engine, $engine_id_file || '' ) if $engine;

	# not Mono-anything, check if it could be ScummVM
	$engine = 'ScummVM' if IndieRunner::Engine::ScummVM::detect_game( undef );
	return ( $engine, $engine_id_file || '' ) if $engine;

	# 2nd Pass: Byte Sequences
	$$self{ mode }->vvsay( 'Engine detection: 2nd pass' ) or
		say STDERR "Failed to identify game engine on first pass; performing second pass.";
	foreach my $f ( @files ) {
		$engine = IndieRunner::GrandCentral::identify_engine_thorough($f);
		if ( $engine ) {
			$engine_id_file = $f;
			say STDERR "second pass result: $engine found in $engine_id_file";
			return ( $engine, $engine_id_file || '' );
		}
	}

	confess "No game engine identified. Aborting.";
}

# heuristic to determine game name
sub detect_game_name ( $engine_module ) {
	my $game_name;

	# 1. try to identify known game from Status-Tracker.md
	#    (XXX: may need quirks before this)
	my @known_games = split( "\n", IndieRunner::Io::read_file( dist_file( 'IndieRunner', 'Status-Tracker.md' ) ) );
	@known_games = grep { /^[[:blank:]]*\|/ } @known_games;
	@known_games = grep { !/^[[:blank:]]*\|[[:blank:]]*Game[[:blank:]]*\|/ } @known_games;
	@known_games = grep { !/^[[:blank:]]*\|[\-[:blank:]]*\|/ } @known_games;
	foreach ( @known_games ) {
		s/^[[:blank:]]*\|[[:blank:]]*([^\|]+)\|.*/$1/g;
		s/[[:blank:]]*$//g;
	}

	# look for file names matching anything in @known_games
	foreach my $g ( @known_games ) {
		my @tokenized = split( /[^[:alnum:]]+/, $g );
		my $game_glob = '*' . join( '*', @tokenized ) . '*';
		if ( defined ( glob( $game_glob ) ) ) {
			return $g;
			last;
		}
	}

	# 2. use engine-specific heuristic from the engine module
	if ( $engine_module->can( 'detect_game' ) ) {
		my $r = $engine_module->detect_game();
		return $r if $r;
	}

	my @exe_files = glob '*.exe';
	if ( @exe_files ) {
		$game_name = $exe_files[0];
		foreach my $e ( @exe_files ) {
			$game_name = $e if length( $e ) < length( $game_name );
		}
		$game_name = substr $game_name, 0, -4;
	}

	$game_name = goggame_name() unless $game_name;
	($game_name) = find_file_magic( '^ELF.*executable', glob '*' ) unless $game_name;
	($game_name) = find_file_magic( '^PE32 executable \(console\)', glob '*' ) unless $game_name;
	$game_name = 'unknown' unless $game_name;	# bail

	# XXX: set $game_name from $$self{ file } if not identified yet

	return $game_name;
}

=head2 setup()

Perform setup for the game.

=cut

sub setup ( $self ) {
	$$self{ mode }->vvsay( 'Setup' );
	$$self{ engine }->setup();
	# XXX: check for dead symlinks?

}

=head2 run()

Configure the runtime binary, arguments, and parameters, then run it.

=cut

sub run ( $self ) {
	$$self{ mode }->vvsay( 'Run' );
	my $configuration_ref = $$self{ game }->configure();
	$$self{ mode }->run( $$self{ game }{ name }, %{ $configuration_ref } );
}

=head2 finish()

Depending on mode, perform remaining tasks after L</run()>.

=cut

sub finish ( $self ) {
	$$self{ mode }->vvsay( 'Finish' );
	$$self{ mode }->finish();
}

1;

__END__

=head1 SUBROUTINES

=head2 detect_engine()

Detect the engine.

=head2 detect_game_name( $engine_module )

Detect the name of the game, using engine-specific heuristics from the C<$engine_module>.

=head1 SEE ALSO

=head2 Engines

L<IndieRunner::Engine::FNA>
L<IndieRunner::Engine::GZDoom>
L<IndieRunner::Engine::Godot>
L<IndieRunner::Engine::HashLink>
L<IndieRunner::Engine::Java>
L<IndieRunner::Engine::Love2D>
L<IndieRunner::Engine::Mono>
L<IndieRunner::Engine::MonoGame>
L<IndieRunner::Engine::ScummVM>
L<IndieRunner::Engine::XNA>

=head2 Other

L<IndieRunner::Mode>
L<IndieRunner::GrandCentral>
L<IndieRunner::Helpers>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2024 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
