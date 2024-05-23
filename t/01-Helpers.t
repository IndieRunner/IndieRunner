#!perl -T

use strict;
use warnings;
use 5.010;

use Test::More tests => 4;

use IndieRunner::IdentifyFiles qw( get_magic_descr find_file_magic );

is( get_magic_descr( 'README' ), 'ASCII text', 'recognize ASCII text file' );

my @directories = find_file_magic( '^directory$', 'Makefile.PL', 'lib', 't' );

is( scalar( @directories ), 2, 'count files with matching libmagic description correctly' );
ok( grep { $_ eq 'lib' } @directories, 'correctly identified lib/ as directory' );
is( grep( { $_ eq 'Makefile.PL' } @directories ), 0, 'don\'t count Makefile.PL as directory' );
