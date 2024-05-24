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

package IndieRunner::Mode;

=head1 NAME

IndieRunner::Mode - parent class of different IndieRunner modes

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use English;
use Readonly;
use File::Spec::Functions qw( devnull splitpath );

=head1 DESCRIPTION

B<Warning! Do not use this class directly, as it is a prototype class for specific IndieRunner modes!>

This is the parent class for the specific mode modules, containing some shared method code. The main modes are L<IndieRunner::Mode::Run> and L<IndieRunner::Mode::Dryrun>. Refer to specific mode modules under L</SEE ALSO> for more information.

=head1 METHODS

=cut

use constant {
	RIGG_NONE	=> 0,
	RIGG_PERMISSIVE	=> 1,
	RIGG_STRICT	=> 2,
	RIGG_DEFAULT	=> 3,
};

Readonly my @NoStrict => (
	'AnodyneSharp',
	'Axiom Verge',
	'Dust: An Elysian Tail',
	'Necrovale',
	'Timespinner',
	);

Readonly my @NoRigg => (
	'tiny_slash',	# aka Cat Warrior
	);

# XXX: remove if not used
Readonly my %PLEDGE_GROUP => (
	'default'	=> [ qw( rpath cpath proc exec prot_exec flock unveil ) ],
	'no_file_mod'	=> [ qw( rpath proc exec prot_exec flock unveil ) ],
	);

sub verbosity( $self ) {
	# default is the reference to the IndieRunner object's verbosity
	# This is overridden if set for this module
	return $$self{ verbosity } || $$self{ ir_obj }{ verbosity };
}

=head2 use_rigg()

Return if rigg is being used. By default use reference to IndieRunner object's attribute use_rigg. Can be overridden/replaced by setting it for this module.

=cut

sub use_rigg( $self ) {
	return $$self{ use_rigg } || $$self{ ir_obj }->get_use_rigg;
}


=head2 vsay(@text)

=cut

sub vsay ( $self, @say_args ) {
	# if contains nothing but whitespace, print just an empty line
	my $not_empty= join('', @say_args);
	$not_empty =~ s/\s//g;

	if ( $self->verbosity >= 2 && $not_empty ) {
		say ( '[' . (caller(1))[3] . '] ', @say_args );
		return 1;
	}
	elsif ( $self->verbosity >= 1 ) {
		say @say_args;
		return 1;
	}
	return 0;
}

=head2 vvsay(@text)

=cut

sub vvsay ( $self, @say_args ) {
	# if contains nothing but whitespace, print just an empty line
	my $not_empty= join('', @say_args);
	$not_empty =~ s/\s//g;

	if ( $self->verbosity >= 2 && $not_empty ) {
		say ( '[' . (caller(1))[3] . '] ', @say_args );
		return 1;
	}
	return 0;
}

=head2 vvvsay(@text)

L<perlfunc/say> for up to 3 levels of verbosity.

=cut

sub vvvsay ( $self, @say_args ) {
	# if contains nothing but whitespace, print just an empty line
	my $not_empty= join('', @say_args);
	$not_empty =~ s/\s//g;

	if ( $self->verbosity >= 2 && $not_empty ) {
		say ( '[' . (caller(1))[3] . '] ', @say_args );
		return 1;
	}
	return 0;
}

=head2 new( { verbosity => $verbosity, use_rigg => $rigg_mode } )

Create new mode object to make use of the polymorphism of mode methods.

=cut

# parent for Mode object constructor
sub new ( $class, %init ) {
	my $self = bless {}, $class;
	%$self = ( %$self, %init );

	init_pledge( $self, $$self{ pledge_group } || 'default' );	# XXX: keep?

	return $self;
}

=head2 resolve_rigg_default( $game_name )

Resolve RIGG_DEFAULT into I<strict>, I<permissive>, or disables rigg.
Defaults to I<strict>, unless the game is marked for NoStrict or NoRigg.

=cut

sub resolve_rigg_default( $self, $game_name ) {
	if ( $self->use_rigg == RIGG_DEFAULT ) {
		if ( grep { index( fc($game_name), fc($_) ) != -1 } @NoStrict ) {
			$self->vsay( "defaulting to permissive mode (rigg) for $game_name" );
			$$self{ ir_obj }->set_use_rigg( RIGG_PERMISSIVE );
		}
		elsif ( grep { index( fc($game_name), fc($_) ) != -1 } @NoRigg ) {
			$self->vsay( "by default running $game_name without rigg" );
			$$self{ ir_obj }->set_use_rigg( RIGG_NONE );
		}
		else {
			$$self{ ir_obj }->set_use_rigg( RIGG_STRICT );
		}
	}
	else {
		carp "Ignoring request to resolve rigg status, as it is not set to RIGG_DEFAULT. This should not happen";
	}
}


=head2 extract($file)

File extraction method.

=cut

sub extract ( $self, $file ) {
	$self->vsay( "extracting $file" );
}

=head2 remove($file)

File removal method.

=cut

sub remove ( $self, $file ) {
	$self->vsay( "removing $file" );
}

=head2 restore($file)

File restore method.

=cut

sub restore ( $self, $file ) {
	$self->vsay( "restoring $file" );
}

=head2 insert($oldfile, $newfile)

Method to insert $oldfile as $newfile.

=cut

sub insert ( $self, $oldfile, $newfile ) {
	$self->vsay( "inserting $oldfile as $newfile" );
}

=head2 undo_insert($file)

Reverse L<insert> operation on $file.

=cut

sub undo_insert( $self, $file ) {
	$self->vsay( "restoring original $file" );
}

=head2 convert($from, $to)

Convert file $from to $to. The conversion is determined by the file suffixes.

=cut

sub convert ( $self, $from, $to ) {
	$self->vsay( "converting $from to $to" );
}

=head2 finish()

No-op by default.

=cut

sub finish ( $self ) {
	# no-op by default
}

=head2 check_rigg_binary($file)

Check if the binary $file can be replaced by rigg, disable rigg if not.

=cut

sub check_rigg_binary ( $self, $binary ) {
	return unless $self->use_rigg;
	my @supported_binaries = split( "\n", qx( rigg -l ) );
	my $basename = ( splitpath($binary) )[2];
	if ( grep { $_ eq $basename } @supported_binaries ) {
		$self->vsay( "using rigg for supported binary $basename" );
	}
	else {
		$self->vsay( "rigg disabled (no support for $basename)" );
		$$self{ ir_obj }->set_use_rigg( RIGG_NONE );
	}
}

=head2 run($game_name, %config)

Launch game with a title $game_name, with details passed via %config.

=over 8

=item bin

Binary to launch.

=item env

Array reference holding the environment settings.

=item args

Array reference to arguments to the engine binary.

=back

=cut

sub run ( $self, $game_name, %config ) {
	my $fullbin	= $config{ bin };
	my $bin		= (splitpath( $fullbin ))[2];
	my @rigg_args	= ();

	if ( $self->use_rigg ) {
		$fullbin = 'rigg';

		# build the chain of @rigg_args arguments
		if ( $self->verbosity ) {
			push( @rigg_args, '-v' );
		}
		push( @rigg_args, '-u' );
		if ( $self->use_rigg == RIGG_STRICT ) {
			push( @rigg_args, 'strict' );
		}
		else {
			push( @rigg_args, 'permissive' );
		}
		push ( @rigg_args, $bin );
	}

	my @full_command = ( $fullbin );

	unshift( @full_command, 'env', @{ $config{ env } } ) if ( @{ $config{ env } } );
	push( @full_command, @rigg_args );
	push( @full_command, @{ $config{ args } } ) if ( @{ $config{ args } } );

	$self->vsay( '' );
	$self->vsay( "Lauching $game_name" );
	$self->vsay( 'Executing: ', join( ' ', @full_command ), "\n" );

	return @full_command;
}

=head2 init_pledge($group)

Initialize pledge with promises depending on the $group.

=cut

# XXX: remove if not used
sub init_pledge ( $self, $group ) {
	if ( $OSNAME eq 'OpenBSD') {
		require OpenBSD::Pledge;
		$self->vvvsay( 'pledge promises: ' . join( ' ', @{ $PLEDGE_GROUP{ $group } } ) );
		pledge( @{ $PLEDGE_GROUP{ $group } } ) || die "unable to pledge: $!";
	}
}

1;

__END__

=head1 SEE ALSO

L<IndieRunner::Mode::Run>
L<IndieRunner::Mode::Dryrun>
L<IndieRunner::Mode::Script>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2024 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
