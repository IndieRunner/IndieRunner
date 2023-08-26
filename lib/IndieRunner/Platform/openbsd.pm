package IndieRunner::Platform::openbsd;

# Copyright (c) 2022-2023 Thomas Frohwein
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
use autodie;

use base qw( Exporter );
our @EXPORT_OK = qw( init );

use OpenBSD::Unveil;

use IndieRunner::Cmdline qw( cli_dllmap_file cli_tmpdir cli_verbose cli_userdir );

my %unveil_paths = (
	'/usr/libdata/perl5/'			=> 'r',
	'/usr/local/lib/'			=> 'r',
	'/usr/local/libdata/perl5/site_perl/'	=> 'r',
	'/usr/local/share/misc/magic.mgc'	=> 'r',
	);

#sub _pledge () {
#}

sub _unveil () {
	my $verbose = cli_verbose();

	# XXX: add work directory to %unveil_paths rwc: cli_userdir

	# XXX: add logfile directory to %unveil_paths wc: cli_tmpdir

	# XXX: add unveil x for the runtime binary

	# XXX: add unveil r for configuration files: cli_dllmap_file

	say 'unveil the following directories:' if $verbose;
	foreach my $k ( keys %unveil_paths ) {
		say "$k -- $unveil_paths{ $k }" if $verbose;
	}
}

sub init ( $self ) {
	_unveil();
	#XXX: _pledge();
	return 1;
}

1;
