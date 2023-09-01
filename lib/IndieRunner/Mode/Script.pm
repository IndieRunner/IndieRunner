package IndieRunner::Mode::Script;

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
use English;

use parent 'IndieRunner::Mode';

use Carp;
use File::Share qw( :all );
use File::Spec::Functions qw( catfile );

my $out;	# accumulates all script output lines which will be printed to stdout in the end

sub script_head () {
	if ( $OSNAME eq 'openbsd' ) {
		my $license = "#!/bin/ksh\n" . IndieRunner::Io::read_file(
				catfile( dist_file( 'IndieRunner', 'LICENSE' ) )
				);
		$license =~ s/\n/\n\# /g;
		$license =~ s/\n\#[[:blank:]]+$//;
		$license .= "\n";
		return $license;
	}
	else {
		confess 'Non-OpenBSD OS not implemented';
	}
}

sub new ( $class, %init ) {
	$out = script_head();
	$init{ pledge_group } = 'no_file_mod';
	$init{ verbosity } = 0;	# don't print verbose message which would mess up script output
	return $class->SUPER::new( %init );
}

sub finish ( $self ) {
	say $out;
}

1;
