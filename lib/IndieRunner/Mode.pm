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

# XXX: remove if not used
Readonly my %PLEDGE_GROUP => (
	'default'	=> [ qw( rpath cpath proc exec prot_exec flock unveil ) ],
	'no_file_mod'	=> [ qw( rpath proc exec prot_exec flock unveil ) ],
	);

my $verbosity;
my $rigg_unveil;

=head2 vsay(@text)

=cut

sub vsay ( $self, @say_args ) {
	# if contains nothing but whitespace, print just an empty line
	my $not_empty= join('', @say_args);
	$not_empty =~ s/\s//g;

	if ( $verbosity >= 2 && $not_empty ) {
		say ( '[' . (caller(1))[3] . '] ', @say_args );
		return 1;
	}
	elsif ( $verbosity >= 1 ) {
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

	if ( $verbosity >= 2 && $not_empty ) {
	#if ( $verbosity >= 2 ) {
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

	if ( $verbosity >= 2 && $not_empty ) {
	#if ( $verbosity >= 3 ) {
		say ( '[' . (caller(1))[3] . '] ', @say_args );
		return 1;
	}
	return 0;
}

=head2 new( { verbosity => $verbosity, rigg_unveil => $rigg_mode } )

Create new mode object to make use of the polymorphism of mode methods.

=cut

# parent for Mode object constructor
sub new ( $class, %init ) {
	my $self = bless {}, $class;
	%$self = ( %$self, %init );

	# make verbosity available for vsay etc.
	$verbosity =	$$self{ verbosity };
	$rigg_unveil =	$$self{ rigg_unveil };

	init_pledge( $self, $$self{ pledge_group } || 'default' );	# XXX: keep?

	return $self;
}

=head2 extract($file)

File extraction method.

=cut

sub extract ( $self, $file ) {
	vsay $self, "extracting $file";
}

=head2 remove($file)

File removal method.

=cut

sub remove ( $self, $file ) {
	vsay $self, "removing $file";
}

=head2 restore($file)

File restore method.

=cut

sub restore ( $self, $file ) {
	vsay $self, "restoring $file";
}

=head2 insert($oldfile, $newfile)

Method to insert $oldfile as $newfile.

=cut

sub insert ( $self, $oldfile, $newfile ) {
	vsay $self, "inserting $oldfile as $newfile";
}

=head2 undo_insert($file)

Reverse L<insert> operation on $file.

=cut

sub undo_insert( $self, $file ) {
	vsay $self, "restoring original $file";
}

=head2 convert($from, $to)

Convert file $from to $to. The conversion is determined by the file suffixes.

=cut

sub convert ( $self, $from, $to ) {
	vsay $self, "converting $from to $to";
}

=head2 finish()

No-op by default.

=cut

sub finish ( $self ) {
	# no-op by default
}

=head2 check_rigg($file)

Check if the binary $file can be replaced by rigg, disable rigg if not.

=cut

sub check_rigg ( $self, $binary ) {
	my @supported_binaries = split( "\n", qx( rigg -l ) );
	my $basename = ( splitpath($binary) )[2];
	if ( grep { $_ eq $basename } @supported_binaries ) {
		vsay $self, "replacing $basename with rigg for execution";
	}
	else {
		vsay $self, "rigg disabled (no support for $basename)";
		$$self{ rigg_unveil } = $rigg_unveil = RIGG_NONE;
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

	if ( $rigg_unveil ) {
		$fullbin = 'rigg';

		# resolve RIGG_DEFAULT into either strict or permissive
		if ( $rigg_unveil == RIGG_DEFAULT and
		     grep { index( fc($game_name), fc($_) ) != -1 } @NoStrict ) {
			     vsay $self, "defaulting to permissive mode (rigg) for $game_name";
			     $rigg_unveil = RIGG_PERMISSIVE;
		}
		elsif ( $rigg_unveil == RIGG_DEFAULT ) {
			$rigg_unveil = RIGG_STRICT;
		}

		# build the chain of @rigg_args arguments
		if ( $verbosity ) {
			push( @rigg_args, '-v' );
		}
		push( @rigg_args, '-u' );
		if ( $rigg_unveil == RIGG_STRICT ) {
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
	vsay $self, "Lauching $game_name";
	vsay $self, "Executing: " . join( ' ', @full_command ) . "\n";

	return @full_command;
}

=head2 init_pledge($group)

Initialize pledge with promises depending on the $group.

=cut

# XXX: remove if not used
sub init_pledge ( $self, $group ) {
	if ( $OSNAME eq 'OpenBSD') {
		require OpenBSD::Pledge;
		vvvsay '', 'pledge promises: ' . join( ' ', @{ $PLEDGE_GROUP{ $group } } );
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

=cut
