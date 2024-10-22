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

package IndieRunner::Engine::Java::LibGDX;
use v5.36;
use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use autodie;
use English;
use parent 'IndieRunner::Engine::Java::JavaMod';

use Carp qw( cluck confess );

use File::Find::Rule;
use File::Path qw( remove_tree );
use File::Spec::Functions qw( catdir catfile splitdir splitpath );
use List::Util qw( max );
use Readonly;

use IndieRunner::Helpers;
use IndieRunner::Io;

Readonly my $So_Sufx => '.so';

Readonly my $GDX_BUNDLED_LOC	=> 'com/badlogic/gdx';
Readonly my $GDX_VERSION_FILE	=> 'Version.class';
Readonly my $GDX_VERSION_REGEX	=> '\d+\.\d+\.\d+';
Readonly my $GDX_NATIVE_LOC	=> '/usr/local/share/libgdx';

my $native_gdx;

sub select_most_compatible_version ( $target_v, @other_v ) {
	# takes target version, followed by array of candidate version numbers
	# as argument (@_)
	# 1. if target version is '_MAX_', then select the highest version
	# 2. returns the matching version amongst the candidates if exists, or
	# 3. returns the lowest of version numbers higher than target, or
	# 4. returns the highest candidate version among lower numbers

	# convert all arguments with version->declare
	# are all supplied arguments valid version strings? (or '_MAX_'?)
	foreach ( @other_v ) {
		$_ = version->declare($_);
		unless ( $_->is_lax() ) {
			die "invalid version string argument to subroutine";
		}
	}

	# 1. if target_v is '_MAX_', return highest version
	if ( $target_v eq '_MAX_' ) {
		return max(@other_v);
	}

	# 2. if match exists, return the first one
	foreach my $candidate_v (@other_v) {
		if ( $candidate_v == $target_v ) {
			return $candidate_v;
		}
	}

	# 3. returns the lowest of version numbers higher than target, or
	foreach my $candidate_v ( sort(@other_v) ) {
		if ( $candidate_v > $target_v ) {
			return $candidate_v;
		}
	}

	# 4. returns the highest candidate version among lower numbers
	foreach my $candidate_v ( sort {$b cmp $a} @other_v ) {
		if ( $candidate_v < $target_v ) {
			return $candidate_v;
		}
	}

	confess "Unable to find a replacement version";	# this shouldn't be reached
}

sub get_bundled_gdx_version () {
	my $gdx_version_file = catfile( $GDX_BUNDLED_LOC, $GDX_VERSION_FILE );
	return '' unless ( -e $gdx_version_file );
	return IndieRunner::Helpers::match_bin_file( $GDX_VERSION_REGEX,
		$gdx_version_file );
}

sub get_native_gdx ( $bundled_v ) {
	my %candidate_replacements =	# keys: version, values: location
		map { IndieRunner::Helpers::match_bin_file( $GDX_VERSION_REGEX, $_) =>
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

sub add_classpath ( $self ) { # XXX: remove? not called by anything
	#return ( $native_gdx ); # XXX: not working currently
	#say "DEBUG: native_gdx - $native_gdx";
	#exit;
	return ( '/usr/local/share/libgdx/1.9.9' );
}

sub setup ( $, $mode_obj ) {

	# What version is bundled with the game?
	my $bundled_v = get_bundled_gdx_version();
	if ( $bundled_v ) {
		$mode_obj->vsay( "Identified bundled LibGDX version: $bundled_v" );
	}
	else {
		$mode_obj->vsay( "WARNING: unable to identify bundled LibGDX version" );
	}

	# Choose a native LibGDX implementation based on the bundled version
	$native_gdx = get_native_gdx( $bundled_v );	# get the location to use
	say "Will use system LibGDX at: $native_gdx";
	unless( $native_gdx ) {
		confess "Can't proceed: unable to find native LibGDX implementation";
	}

	# insert framework libraries
	foreach my $l ( glob $native_gdx . '/*.so' ) {
		$mode_obj->insert( $l, ( splitpath( $l ) )[2] );
	}

	# insert framework managed code (class files)
	$mode_obj->insert( catdir( $native_gdx, $GDX_BUNDLED_LOC ), $GDX_BUNDLED_LOC );
}

1;
