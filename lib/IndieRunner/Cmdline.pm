package IndieRunner::Cmdline;

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
our @EXPORT_OK = qw( cli_dllmap_file cli_dryrun cli_file cli_gameargs
                     cli_mode cli_verbose init_cli );

use File::Spec::Functions qw( catdir );
use FindBin;
use Getopt::Long;
use Pod::Usage;

use IndieRunner::Io;

my $game_dir = '';
my $cli_file = '';
my $dllmap_file = '';
my $engine_name = '';
my $game_name;
my $mode	= 'run';	# run, dryrun, or script
my $verbose	= 0;

sub init_cli () {
	Getopt::Long::Configure ("bundling");
	GetOptions (    'help|h'	=> sub { pod2usage(-exitval => 0, -verbose => 1); },
	                'dir|d=s'	=> \$game_dir,
	                'dllmap|D=s'	=> \$dllmap_file,
			'dryrun|n'      => sub { $mode = 'dryrun'; },
			'engine|e=s'	=> \$engine_name,
			'file|f=s'	=> \$cli_file,
			'game|g=s'	=> \$game_name,
			'man|m'           => sub { pod2usage(-exitval => 0,
			                                     -verbose => 2,
							     -input => "$FindBin::Bin/../lib/IndieRunner.pod"); },
			'script'	=> sub { $mode = 'script' },
			'usage'         => sub { pod2usage(-exitval => 0,
			                                   -verbose => 0,
							   -input => "$FindBin::Bin/../lib/IndieRunner.pod"); },
			'verbose|v'     => \$verbose,
			'version'       => sub { say $VERSION; exit; },
		   )
	or pod2usage(2);

	# apply the immediate rules based on cli args
	chdir $game_dir if $game_dir;
	if ( $mode eq 'script' ) {
		$verbose = 0;		# need to disable verbosity to write script to stdout
		IndieRunner::Io::script_head();
	}

	return {
		game_dir	=> $game_dir,	# XXX; really needed to return, after chdir above?
		cli_file	=> $cli_file,
		dllmap_file	=> $dllmap_file,
		engine_name	=> $engine_name,
		game_args	=> \@ARGV,
		game_name	=> $game_name,
		mode		=> $mode,
		verbose		=> $verbose,
	};
}

sub cli_dllmap_file ()	{ return $dllmap_file; }
sub cli_dryrun ()	{ return $mode eq 'dryrun'; }
sub cli_file ()		{ return $cli_file; }
sub cli_gameargs ()	{
	return '';
}
sub cli_mode ()			{ return $mode; }
sub cli_verbose ()		{ return $verbose; }

1;
