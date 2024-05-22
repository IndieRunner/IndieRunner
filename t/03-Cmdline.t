#!perl -T

use strict;
use warnings;
use 5.010;

use Test::More tests => 2;

use IndieRunner::Cmdline qw( init_cli );

# set to avoid insecure error with Taint mode
$ENV{'PATH'} = '/bin:/usr/bin';
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

my %init_hash = %{ init_cli() };

is(	$init_hash{ dir }, '.',		'default dir \'.\'' );
is(	$init_hash{ verbosity }, 0,	'default verbosity 0' );
