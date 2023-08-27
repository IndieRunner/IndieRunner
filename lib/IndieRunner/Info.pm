package IndieRunner::Info;

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
our @EXPORT_OK = qw( goggame_name steam_appid );

use autodie;
use JSON;
use Path::Tiny;
use Readonly;

Readonly::Scalar my $STEAM_FILE => 'steam_appid.txt';

sub goggame_name () {
	my ($info_file) = glob 'goggame-*.info';
	return '' unless $info_file;

	my $dat = decode_json( path( $info_file )->slurp_utf8 ) or return '';
	( exists $$dat{'name'} ) ? return $$dat{'name'} : return '';
}

# XXX: not used without steamlog/log_steam_time. Remove or resurrect?
sub steam_appid () {
	return '' unless -f $STEAM_FILE;
	return path( $STEAM_FILE )->slurp_utf8;
}

1;
