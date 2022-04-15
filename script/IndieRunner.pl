#! /usr/bin/perl

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use Getopt::Long;
use File::Find::Rule;
use FindBin; use lib "$FindBin::Bin/../lib";
use Pod::Usage;

use IndieRunner::GrandCentral;

### process config & options ###

my $verbose;	# flags

GetOptions (	"help|h"	=> sub { pod2usage(1) },
		"man"		=> sub { pod2usage(-exitval => 0, -verbose => 2) },
		"verbose|v"	=> \$verbose,
	) or pod2usage(2);

### detect game engine ###

### detect bundled dependencies ###

### hand off to the module for the engine ###
