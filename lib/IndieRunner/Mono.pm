package IndieRunner::Mono;

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( $BIN );

use Carp;
use Readonly;

Readonly::Scalar our $BIN => 'mono';

1;
