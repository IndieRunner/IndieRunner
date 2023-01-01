package IndieRunner::Java::LibGDX;

# Copyright (c) 2022 Thomas Frohwein
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

use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use strict;
use warnings;
use v5.10;
use autodie;
use Carp qw( cluck confess );

use File::Copy::Recursive qw( dircopy );
use File::Find::Rule;
use File::Path qw( remove_tree );
use File::Spec::Functions qw( catdir catfile splitdir splitpath );
use List::Util qw( max );
use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::Io qw( ir_symlink );
use IndieRunner::Platform qw( get_os );

Readonly::Scalar my $So_Sufx => '.so';

Readonly::Array my @LIB_LOCATIONS
        => ( '/usr/X11R6/lib',
	     '/usr/local/lib',
	     '/usr/local/share/lwjgl',
);

Readonly::Scalar my $GDX_BUNDLED_LOC	=> 'com/badlogic/gdx';
Readonly::Scalar my $GDX_VERSION_FILE	=> 'Version.class';
Readonly::Scalar my $GDX_VERSION_REGEX	=> '\d+\.\d+\.\d+';
Readonly::Scalar my $GDX_NATIVE_LOC	=> '/usr/local/share/libgdx';

my $native_gdx;

sub select_most_compatible_version {
	# takes target version, followed by array of candidate version numbers
	# as argument (@_)
	# 1. if target version is '_MAX_', then select the highest version
	# 2. returns the matching version amongst the candidates if exists, or
	# 3. returns the lowest of version numbers higher than target, or
	# 4. returns the highest candidate version among lower numbers

	die "too few arguments to subroutine" unless scalar( @_ ) > 1;

	my $target_v = shift(@_);

	# convert all arguments with version->declare
	# are all supplied arguments valid version strings? (or '_MAX_'?)
	foreach ( @_ ) {
		$_ = version->declare($_);
		unless ( $_->is_lax() ) {
			die "invalid version string argument to subroutine";
		}
	}

	# 1. if target_v is '_MAX_', return highest version
	if ( $target_v eq '_MAX_' ) {
		return max(@_);
	}

	# 2. if match exists, return the first one
	foreach my $candidate_v (@_) {
		if ( $candidate_v == $target_v ) {
			return $candidate_v;
		}
	}

	# 3. returns the lowest of version numbers higher than target, or
	foreach my $candidate_v ( sort(@_) ) {
		if ( $candidate_v > $target_v ) {
			return $candidate_v;
		}
	}

	# 4. returns the highest candidate version among lower numbers
	foreach my $candidate_v ( sort {$b cmp $a} @_ ) {
		if ( $candidate_v < $target_v ) {
			return $candidate_v;
		}
	}

	confess "Unable to find a replacement version";	# this shouldn't be reached
}

sub replace_lib {
	my $lib = shift;

	my $lib_glob;		# pattern to search for $syslib

	my @candidate_syslibs;

	# create glob string 'libxxx{64,}.so*'
	($lib_glob = $lib) =~ s/(64)?.so$//;
	$lib_glob = $lib_glob . "{64,}.so*";

	foreach my $l ( @LIB_LOCATIONS, $native_gdx ) {
		ir_symlink( catfile( $l, $lib_glob ), $lib, 1 ) and return 1;
	}

	return 0;
}

sub get_bundled_gdx_version {
	my $gdx_version_file = catfile( $GDX_BUNDLED_LOC, $GDX_VERSION_FILE );
	return '' unless ( -e $gdx_version_file );
	return IndieRunner::Java::match_bin_file( $GDX_VERSION_REGEX,
		$gdx_version_file );
}

sub get_native_gdx {
	my $bundled_v = shift;

	my %candidate_replacements =	# keys: version, values: location
		map { IndieRunner::Java::match_bin_file( $GDX_VERSION_REGEX, $_) =>
			( splitpath($_) )[1]
		    } File::Find::Rule->file
				      ->name( $GDX_VERSION_FILE )
				      ->in( $GDX_NATIVE_LOC );
	my $most_compatible_version = select_most_compatible_version( $bundled_v,
				keys( %candidate_replacements ) );
	my @location = splitdir( $candidate_replacements{ $most_compatible_version } );
	@location = splice @location, 0, (scalar @location - 4);
	return ( catdir( @location ) );
}

sub add_classpath {
	return ( $native_gdx );
}

sub setup {
	my ($self) = @_;
	my $dryrun = cli_dryrun();
	my $verbose = cli_verbose();

	# What version is bundled with the game?
	my $bundled_v = get_bundled_gdx_version();
	if ( $bundled_v and $verbose ) {
		say "Identified bundled LibGDX version: $bundled_v";
	}
	elsif ( $verbose ) {
		say "WARNING: unable to identify bundled LibGDX version";
	}

	# Choose a native LibGDX implementation based on the bundled version
	$native_gdx = get_native_gdx( $bundled_v );	# get the location to use
	say "Will use system LibGDX at: $native_gdx";
	unless( $native_gdx ) {
		confess "Can't proceed: unable to find native LibGDX implementation";
	}

	say "\nChecking which libraries are present...";
	my @bundled_libs	= glob( '*' . $So_Sufx );
	my ($f, $l);	# f: regular file test, l: symlink test
	foreach my $file (@bundled_libs) {
		print $file . ' ... ' if ( $verbose or $dryrun );
		($f, $l) = ( -f $file , -l $file );

		# F L: symlink to existing file => everything ok
		# F l: non-symlink file => needs fixing
		# f L: broken symlink => needs fixing
		# f l: no file found (impossible after glob above)
		if ($f and $l) {
			say 'ok' if ( $verbose or $dryrun );
			next;
		}
		else {
			replace_lib($file) or say "no match - skipped";
		}
	}
	# quirk for Gunslugs which doesn't bundle libgdx-controllers-desktop64.so,
	# but requires it
	# XXX: make it smarter
	ir_symlink( catfile( $native_gdx, 'libgdx-controllers-desktop64.so' ),
	            'libgdx-controllers-desktop64.so');
	say '';
}

1;
