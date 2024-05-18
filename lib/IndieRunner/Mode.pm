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
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use English;
use Readonly;

use File::Spec::Functions qw( devnull splitpath );

use constant {
	RIGG_NONE	=> 0,
	RIGG_PERMISSIVE	=> 1,
	RIGG_STRICT	=> 2,
};

# XXX: remove if not used
Readonly my %PLEDGE_GROUP => (
	'default'	=> [ qw( rpath cpath proc exec prot_exec flock unveil ) ],
	'no_file_mod'	=> [ qw( rpath proc exec prot_exec flock unveil ) ],
	);

my $verbosity;
my $rigg_unveil;

sub vsay ( $self, @say_args ) {
	if ( $verbosity >= 2 ) {
		say ( '[' . (caller(1))[3] . '] ', @say_args );
		return 1;
	}
	elsif ( $verbosity >= 1 ) {
		say @say_args;
		return 1;
	}
	return 0;
}

sub vvsay ( $self, @say_args ) {
	if ( $verbosity >= 2 ) {
		say ( '[' . (caller(1))[3] . '] ', @say_args );
		return 1;
	}
	return 0;
}

sub vvvsay ( $self, @say_args ) {
	if ( $verbosity >= 3 ) {
		say ( '[' . (caller(1))[3] . '] ', @say_args );
		return 1;
	}
	return 0;
}

# parent for Mode object constructor
sub new ( $class, %init ) {
	my $self = bless {}, $class;
	%$self = ( %$self, %init );

	# make verbosity available for vsay etc.
	$verbosity =	$$self{ verbosity };
	$rigg_unveil =	$$self{ rigg_unveil };

	init_pledge( $$self{ pledge_group } || 'default' );

	return $self;
}

sub extract ( $self, $file ) {
	vsay $self, "extracting $file";
}

sub remove ( $self, $file ) {
	vsay $self, "removing $file";
}

sub insert ( $self, $oldfile, $newfile ) {
	vsay $self, "inserting $oldfile as $newfile";
}

sub convert ( $self, $from, $to ) {
	vsay $self, "converting $from to $to";
}

sub finish ( $self ) {
	# no-op by default
}

sub run ( $self, $game_name, %config ) {
	my $fullbin	= $config{ bin };
	my $bin		= (splitpath( $fullbin ))[2];
	my @rigg_args	= ();

	my $fullrigg	= qx( which rigg 2> /dev/null );
	chomp $fullrigg;

	if ( $fullrigg and $rigg_unveil ) {
		# check if rigg supports the binary
		my @rigg_supported_binaries = split( "\n", qx( rigg -l ) );
		if ( grep { $_ eq $bin } @rigg_supported_binaries ) {
			vsay "rigg binary found at: $fullrigg";
			vsay "replacing $bin is with rigg for execution";
			$fullbin = 'rigg';
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
	}

	my @full_command = ( $fullbin );

	unshift( @full_command, 'env', @{ $config{ env } } ) if ( @{ $config{ env } } );
	push( @full_command, @rigg_args );
	push( @full_command, @{ $config{ args } } ) if ( @{ $config{ args } } );

	vsay $self, "\nLauching $game_name";
	vsay $self, "Executing: " . join( ' ', @full_command ) . "\n";

	return @full_command;
}

sub set_verbosity ( $self, $verbosity ) {
	$$self{ verbosity } = $verbosity;
}

# XXX: remove if not used
sub init_pledge ( $group ) {
	if ( $OSNAME eq 'OpenBSD') {
		require OpenBSD::Pledge;
		vvvsay '', 'pledge promises: ' . join( ' ', @{ $PLEDGE_GROUP{ $group } } );
		pledge( @{ $PLEDGE_GROUP{ $group } } ) || die "unable to pledge: $!";
	}
}

1;
