package IndieRunner::Cmdline;

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

use base qw( Exporter );
our @EXPORT_OK = qw( cli_dryrun cli_file cli_verbose init_cli );

use Getopt::Long;
use Pod::Usage;

my $cli_file;
my $dryrun	= 0;
my $verbose	= 0;

sub init_cli {
	Getopt::Long::Configure ("bundling");
	GetOptions (    "help|h"          => sub { pod2usage(-exitval => 0, -verbose => 1) },
			"dryrun|d"      => \$dryrun,
			"man"           => sub { pod2usage(-exitval => 0, -verbose => 2) },
			"usage"         => sub { pod2usage(-exitval => 0, -verbose => 0) },
			"verbose|v"     => \$verbose,
			"version"       => sub { say $VERSION; exit; },
		   )
	or pod2usage(2);
	$cli_file = $ARGV[0] || '';
}

sub cli_dryrun	{ return $dryrun; }
sub cli_file	{ return $cli_file; }
sub cli_verbose	{ return $verbose; }

1;
