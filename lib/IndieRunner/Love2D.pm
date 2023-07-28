package IndieRunner::Love2D;

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
use autodie;
use Carp;

use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );

Readonly::Array my @LOVE2D_ENV => (
	'LUA_CPATH=/usr/local/lib/luasteam.so',
	);

Readonly::Hash my %LOVE2D_VERSION_STRINGS => {
	'0.9.x'		=> '0\.9\.[0-9]',
	'0.10.x'	=> '0\.10\.[0-9]',
	'11.x'		=> '11\.[0-9]',
	};

Readonly::Hash my %LOVE2D_VERSION_BIN => {
	'0.8.x'		=> 'love-0.8',
	'0.9.x'		=> 'love-0.9',		# not in ports July 2023
	'0.10.x'	=> 'love-0.10',
	'11.x'		=> 'love-11',
	};

my $bin;

sub run_cmd {
	my ($self, $engine_id_file) = @_;
	IndieRunner::set_game_name( (split /\./, $engine_id_file)[0] );
	confess "not implemented";
	#return ( $BIN, '--main-pack', $engine_id_file );
}

sub setup {
	my ($self) = @_;

	my $dryrun = cli_dryrun();
	my $verbose = cli_verbose();

	# TODO: complete
}

1;
