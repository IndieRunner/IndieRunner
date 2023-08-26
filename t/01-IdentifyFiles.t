#!perl -T

use strict;
use warnings;
use 5.010;

use Test::Simple tests => 1;

use IndieRunner::IdentifyFiles qw( get_magic_descr );

ok( get_magic_descr( 'README' ) eq 'ASCII text', 'recognize ASCII text file' );
