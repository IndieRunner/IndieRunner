package IndieRunner::Java;

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

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use Carp;

use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::IdentifyFiles qw( get_magic_descr );	# XXX: is this used here?

# Java version string examples: '1.8.0_312-b07'
#                               '1.8.0_181-b02'
#                               '11.0.13+8-1'
#                               '17.0.1+12-1'
Readonly::Scalar my $JAVA_VER_REGEX
				=> '\d{1,2}\.\d{1,2}\.\d{1,2}[_\+][\w\-]+';

Readonly::Hash my %managed_subst => (
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

Readonly::Array my @LIB_LOCATIONS
        => ( '/usr/X11R6/lib',
	     '/usr/local/lib',
	     '/usr/local/share/lwjgl',
	     '/usr/local/share/libgdx',
);

my %Valid_Java_Versions = (
	'openbsd'       => [
				'1.8.0',
				'11',
				'17',
			   ],
);

# ... TODO: copy more over from libgdx-run

sub run_cmd {
	my ($self, $game_file) = @_;

	croak "Not implemented yet";
}

sub setup {
	my ($self) = @_;
	my $dryrun = cli_dryrun;
	my $verbose = cli_verbose;

	croak "Not implemented yet";
}

1;
