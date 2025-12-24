# Copyright (c) 2022-2025 Thomas Frohwein
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

=head1 NAME

IndieRunner::Engine::Java::LibGDX - module for LibGDX

=head1 DESCRIPTION

This module assists with setup for Java games that use the LibGDX framework.

=over 8

=cut

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

Readonly my %GDX_JAVA_VERSION => (
	'openbsd'	=> '11',
	);

my $native_gdx;

=item select_most_compatible_version($target_v, @candidate_v)

Heuristic to pick a version of LibGDX to use from an array of possible candidates.

=cut

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

=item get_min_java_v()

Return the preferred Java version to use for LibGDX games.
This is dependent on the operating system.

=cut

sub get_min_java_v ( $ ) {
	return $GDX_JAVA_VERSION{ $OSNAME };
}

=item get_bundled_gdx_version()

Returns the version of the bundled LibGDX.

=cut

sub get_bundled_gdx_version () {
	my $gdx_version_file = catfile( $GDX_BUNDLED_LOC, $GDX_VERSION_FILE );
	return '' unless ( -e $gdx_version_file );
	return IndieRunner::Helpers::match_bin_file( $GDX_VERSION_REGEX,
		$gdx_version_file );
}

=item get_native_gdx($bundled_v)

Using the bundled LibGDX version number, this subroutine returns the system directory location of the most appropriate version of LibGDX.

=cut

sub get_native_gdx ( $bundled_v ) {
	my %candidate_replacements =	# keys: version, values: location
		map { IndieRunner::Helpers::match_bin_file( $GDX_VERSION_REGEX, $_) =>
			( splitpath($_) )[1]
		    } File::Find::Rule->file
				      ->name( $GDX_VERSION_FILE )
				      ->in( $GDX_NATIVE_LOC );
	# XXX: hack to proceed with *some* version if no bundled_v found,
	#      e.g. PuppyGames titles
	my $most_compatible_version = select_most_compatible_version( $bundled_v || 0,
				keys( %candidate_replacements ) );
	my @location = splitdir( $candidate_replacements{ $most_compatible_version } );
	@location = splice @location, 0, (scalar @location - 4);
	return ( catdir( @location ) );
}

=item add_classpath()

Return what to add to classpath.

=cut

sub add_classpath ( $self ) { # XXX: remove? not called by anything
	#return ( $native_gdx ); # XXX: not working currently
	#say "DEBUG: native_gdx - $native_gdx";
	#exit;
	return ( '/usr/local/share/libgdx/1.9.9' );
}

=item setup($mode_obj)

Setup steps for LWJGL3 framework.
Determines the version of native LibGDX to use for this game to insert the native and managed libraries.

=cut

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

	# insert framework managed code (class files) if exists
	if (-d $GDX_BUNDLED_LOC) {
		$mode_obj->insert( catdir( $native_gdx, $GDX_BUNDLED_LOC ),
				   $GDX_BUNDLED_LOC );
	}
	else {
		$mode_obj->vsay( "No managed LibGDX libraries at $GDX_BUNDLED_LOC" );
	}
}

1;

__END__

=back

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

=head1 SEE ALSO

L<IndieRunner::Engine::Java>,
L<IndieRunner::Engine::Java::JavaMod>.

=head1 COPYRIGHT

Copyright 2022-2025 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.
