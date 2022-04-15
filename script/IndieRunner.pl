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

__END__

=head1 NAME

IndieRunner - Launch your indie games on more platforms

=head1 SYNOPSIS

IndieRunner [options]

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message.

=item B<-man>

Prints the manual page and exits.

=item B<-verbose>

Enable verbose output.

=back

=head1 DESCRIPTION

B<IndieRunner> provides a convenient way to launch indie games with supported engines.

=head2 Supported Engines

=over 8

=item FNA (under construction)

=item Godot (under construction)

=item HashLink (under construction)

=item LibGDX (under construction)

=item LWJGL (under construction)

=item XNA (under construction)

=back

=cut
