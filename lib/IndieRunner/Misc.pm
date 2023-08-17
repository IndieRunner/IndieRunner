package IndieRunner::Misc;

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
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( log_steam_time );

use Carp;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );

sub log_steam_time ( $appid = '' ) {	# requires steamctl in path
	confess 'Option `--log-steam-time without AppId' unless $appid;
	my $verbose = cli_verbose();

	my $p = fork();
	if ( $p == 0 ) {
		exit if cli_dryrun();
		say "Starting game time logging on Steam using steamctl" if $verbose;
		exec "steamctl assistant idle-games $appid"
			or confess 'Failed to launch logging process';
	}
	else {
		return $p;
	}
}

1;
