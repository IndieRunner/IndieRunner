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
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( cli_appid cli_dllmap_file cli_dryrun cli_file
                     cli_log_steam_time cli_mode cli_tmpdir cli_verbose
                     cli_userdir init_cli );

use File::Spec::Functions qw( catdir );
use Getopt::Long;
use Pod::Usage;

my $appid	= '';		# Steam AppID, for use with --log-steam-time
my $cli_file;
my $dllmap_file;
my $log_steam_time;
my $tmpdir	= '/tmp/IndieRunner/';
my $userdir	= catdir( $ENV{HOME}, '.IndieRunner' );
my $verbose	= 0;
my $mode	= 'run';	# run, dryrun, or script

sub init_cli {
	Getopt::Long::Configure ("bundling");
	GetOptions (    'help|h'	=> sub { pod2usage(-exitval => 0, -verbose => 1); },
	                'appid|a=s'	=> \$appid,
	                'dllmap|D=s'	=> \$dllmap_file,
			'dryrun|d'      => sub { $mode = 'dryrun'; },
			# XXX: "logdir|L=s"	=> \$logdir,?? equals tmpdir?
			'log-steam-time'=> \$log_steam_time,
			'man|m'           => sub { pod2usage(-exitval => 0, -verbose => 2); },
			'script'	=> sub { $mode = 'script' },
			'usage'         => sub { pod2usage(-exitval => 0, -verbose => 0); },
			# XXX: "userdir" ??
			'verbose|v'     => \$verbose,
			'version'       => sub { say $VERSION; exit; },
		   )
	or pod2usage(2);
	$cli_file = $ARGV[0] || '';
}

sub cli_appid		{ return $appid; }
sub cli_dllmap_file	{ return $dllmap_file; }
sub cli_dryrun		{ return $mode eq 'dryrun'; }
sub cli_file		{ return $cli_file; }
sub cli_log_steam_time	{ return $log_steam_time; }
sub cli_mode		{ return $mode; }
sub cli_tmpdir		{ return $tmpdir; }
sub cli_userdir		{ return $userdir; }
sub cli_verbose		{ return $verbose; }

1;
