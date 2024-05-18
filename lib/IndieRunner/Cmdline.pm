# Copyright (c) 2022-2024 Thomas Frohwein
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

package IndieRunner::Cmdline;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use Getopt::Long;
use Pod::Usage;

use constant {
	RIGG_NONE	=> 0,
	RIGG_PERMISSIVE	=> 1,
	RIGG_STRICT	=> 2,
};

my $dir = '.';
my $dllmap;
my $dryrun;
my $engine;
my $file;
my $game;
my $mode;
my $rigg_unveil = RIGG_STRICT;
my $script;
my $verbosity = 0;

sub init_cli () {
	Getopt::Long::Configure ("bundling");
	GetOptions (    'help|h'	=> sub { pod2usage(-exitval => 0, -verbose => 1); },
	                'directory|d=s'	=> \$dir,
	                'dllmap|D=s'	=> \$dllmap,
			'dryrun|n'	=> \$dryrun,
			'engine|e=s'	=> \$engine,
			'file|f=s'	=> \$file,
			'game|g=s'	=> \$game,
			'man|m'		=> sub { pod2usage(-exitval => 0,
			                                     -verbose => 2, ); },
			'norigg'	=> sub { $rigg_unveil = RIGG_NONE; },
			'permissive|p'	=> sub { $rigg_unveil = RIGG_PERMISSIVE; },
			'script|s'	=> \$script,
			'usage'		=> sub { pod2usage(-exitval => 0,
			                                   -verbose => 0, ); },
			'verbose|v+'	=> \$verbosity,
			'version|V'	=> sub { say $VERSION; exit; },	# XXX: $VERSION from which module or script?
		   )
	or pod2usage(2);

	# keep this in sync with %INIT_ATTRIBUTES_DEFAULTS in IndieRunner.pm
	return {
		dir		=> $dir,
		dllmap		=> $dllmap,
		dryrun		=> $dryrun,
		engine		=> $engine,
		file		=> $file,
		game		=> $game,
		game_args	=> \@ARGV,
		rigg_unveil	=> $rigg_unveil,
		script		=> $script,
		verbosity	=> $verbosity,
	};
}

1;

__END__

=head1 NAME

IndieRunner::Cmdline - command-line parser for construction of IndieRunner object

=head1 SYNOPSIS

 use IndieRunner::Cmdline;

 # obtain hash for IndieRunner CLI configuration
 my %indierunner_config = IndieRunner::Cmdline::init_cli()

=head1 DESCRIPTION

IndieRunner::Cmdline provides subroutine init_cli() which is meant to be used by a command-line client to configure the creation of IndieRunner object. It is little more than creation of a hash from the commandline arguments. It leaves the use of default values to IndieRunner.

=head1 SEE ALSO

L<IndieRunner>, L<indierunner>.

=head1 AUTHOR

Thomas Frohwein
