package IndieRunner::Cmdline;
use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( cli_dryrun cli_file cli_verbose init_cli );

use Getopt::Long;
use Pod::Usage;

my $cli_file;
my $dryrun	= 0;
my $verbose	= 0;

sub init_cli {
	Getopt::Long::Configure ("bundling");
	GetOptions (    "help"          => sub { pod2usage(-exitval => 0, -verbose => 1) },
			"dryrun|d"      => \$dryrun,
			"man"           => sub { pod2usage(-exitval => 0, -verbose => 2) },
			"usage"         => sub { pod2usage(-exitval => 0, -verbose => 0) },
			"verbose|v"     => \$verbose,
			"version"       => sub { say $VERSION; exit; },
		   )
	or pod2usage(2);
	$cli_file = $ARGV[0] || '';
}

sub cli_dryrun	{ return $dryrun; }
sub cli_file	{ return $cli_file; }
sub cli_verbose	{ return $verbose; }

1;
