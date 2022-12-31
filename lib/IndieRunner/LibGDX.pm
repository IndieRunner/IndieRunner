package IndieRunner::LibGDX;

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
use Carp;

use File::Copy::Recursive qw( dircopy );
use File::Find::Rule;
use File::Path qw( remove_tree );
use File::Spec::Functions qw( catfile splitpath );
use List::Util qw( max );
use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::Io qw( ir_symlink );
use IndieRunner::Java qw( match_bin_file );
use IndieRunner::Platform qw( get_os );

Readonly::Scalar my $So_Sufx => '.so';

# TODO: fix using hardcoded libgdx/1.9.11 path
Readonly::Array my @LIB_LOCATIONS
        => ( '/usr/X11R6/lib',
	     '/usr/local/lib',
	     '/usr/local/share/lwjgl',
	     '/usr/local/share/libgdx/1.9.11',
);

Readonly::Hash my %MANAGED_SUBST => (
	'libgdx' =>             {
				'Bundled_Loc'         => 'com/badlogic/gdx',
				'Replace_Loc'         => '/usr/local/share/libgdx',
				'Version_File'        => 'Version.class',
				'Version_Regex'       => '\d+\.\d+\.\d+',
				'Os_Test_File'        => 'com/badlogic/gdx/utils/SharedLibraryLoader.class',
				},
	'steamworks4j' =>       {
				'Bundled_Loc'         => 'com/codedisaster/steamworks',
				'Replace_Loc'         => '/usr/local/share/steamworks4j',
				'Version_File'        => 'Version.class',
				'Version_Regex'       => '\d+\.\d+\.\d+',
				'Os_Test_File'        => 'com/codedisaster/steamworks/SteamSharedLibraryLoader.class',
				},
);

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

	foreach my $l ( @LIB_LOCATIONS ) {
		ir_symlink( catfile( $l, $lib_glob ), $lib, 1 ) and last;
	}

	return 1;
}

sub replace_managed {
	my $framework_name = shift(@_);

	my $dryrun = cli_dryrun();
	my $verbose = cli_verbose();

	my $bundled_loc;
	my $framework_version;
	my $framework_version_file;
	my $most_compatible_version;
	my $replacement_framework;
	my $version_class_file = $MANAGED_SUBST{ $framework_name }{ 'Version_File' };

	my %candidate_replacements;	# hash of location and version

	# find bundled version
	$bundled_loc	= $MANAGED_SUBST{ $framework_name }{ 'Bundled_Loc' };
	unless ( -e $bundled_loc ) {
		return;	# the framework/managed code doesn't exist
	}
	$framework_version_file	= catfile( $bundled_loc,
					   $version_class_file );

	if ( -f $framework_version_file ) {
		$framework_version = match_bin_file( $MANAGED_SUBST{ $framework_name }{ 'Version_Regex'},
					     $framework_version_file );
		say "found bundled $framework_name, version $framework_version";
	}
	else {
		say "Missing $version_class_file file for $framework_name. Picking highest available one.";
		$framework_version = '_MAX_';
	}

	# find matching replacement
	%candidate_replacements =
		map { match_bin_file( $MANAGED_SUBST{ $framework_name }{ 'Version_Regex' }, $_) =>
			( splitpath($_) )[1]
		    } File::Find::Rule->file
				      ->name( $version_class_file )
				      ->in( $MANAGED_SUBST{ $framework_name }{ 'Replace_Loc' } );
	$most_compatible_version = select_most_compatible_version( $framework_version,
				keys( %candidate_replacements ) );
	$replacement_framework = $candidate_replacements{ $most_compatible_version };
	unless( $replacement_framework ) {
		confess "No matching framework found to replace bundled $framework_name";
	}

	# remove and replace bundled version
	say "replacing bundled $framework_name at '$bundled_loc' with version $most_compatible_version";

	my $r = dircopy( $replacement_framework, $bundled_loc );
}

sub setup {
	my ($self) = @_;
	my $dryrun = cli_dryrun();
	my $verbose = cli_verbose();

	IndieRunner::Java->setup();

	# if managed code doesn't support this operating system, replace it
	foreach my $k ( keys( %MANAGED_SUBST ) ) {
		if ( -e $MANAGED_SUBST{ $k }{ 'Bundled_Loc' }
			and not match_bin_file(get_os(), $MANAGED_SUBST{ $k }{ 'Os_Test_File' }, 1) ) {
				replace_managed($k);
		}
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
			replace_lib($file) or say "couldn't set up library: $file";
		}
	}
	say '';
}

1;
