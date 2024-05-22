#!perl -T

use strict;
use warnings;
use 5.010;

use Test::More tests => 3;

use IndieRunner::Platform qw( get_platforms check_platform );

ok(	check_platform( 'OpenBSD' ),	'recognize OpenBSD as supported platform' );
isnt(	check_platform( 'Foo' ), 1,	'recognize Foo as unsupported platform' );
ok(	get_platforms,			'get_platforms returns an array >= 1' );
