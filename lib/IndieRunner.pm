package IndieRunner;

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

use Capture::Tiny ':all';
use File::Find::Rule;
use File::Spec::Functions qw( catpath splitpath );
use List::Util qw( first );
use POSIX qw( strftime );

use IndieRunner::Cmdline qw( cli_appid cli_dryrun cli_file cli_log_steam_time
				cli_mode cli_tmpdir cli_verbose init_cli );
use IndieRunner::FNA;
use IndieRunner::Godot;
use IndieRunner::GrandCentral;
use IndieRunner::GZDoom;
use IndieRunner::HashLink;
use IndieRunner::IdentifyFiles qw( find_file_magic );
use IndieRunner::Info qw( goggame_name steam_appid );
use IndieRunner::Io qw( script_head write_file );
use IndieRunner::Java;
use IndieRunner::Misc qw( log_steam_time );
use IndieRunner::Mono qw( get_mono_files );
use IndieRunner::MonoGame;
use IndieRunner::XNA;

my $game_name = '';
sub set_game_name { $game_name = join( ' ', @_); }

# process config & options
init_cli;
my $cli_file	= cli_file();
my $tmpdir	= cli_tmpdir();
my $dryrun	= cli_dryrun();
my $verbose	= cli_verbose();
my $mode	= cli_mode();

script_head() if $mode eq 'script';

# TODO:
# - change output drom dryrun mode to be able to create a script
# - then store the scripts in share/ directory
# - manage the share/ dir with File::Share +/- File::ShareDir::Install

# if $cli_file contains directory, switch to that directory
if ( $cli_file ) {
	die "No such file or directory: $cli_file" unless ( -e $cli_file );
	if ( -d $cli_file ) {
		chdir $cli_file;
		undef $cli_file;
	}
	else {
		my ($gf_volume, $gf_directories, $gf_file) = splitpath( $cli_file );
		chdir $gf_volume . $gf_directories if ( $gf_directories );
	}
}

# XXX: process config file

# detect game engine
my $engine;
my $engine_id_file;
my @files = File::Find::Rule->file()->maxdepth( 3 )->in( '.' );	# XXX: is maxdepth 3 enough?

# 1st Pass: File Names
foreach my $f ( @files ) {
	# use just basename of file, as different games put those files
	# in different directories
	my $basename = (splitpath( $f ))[2];
	$engine = IndieRunner::GrandCentral::identify_engine($basename);
	if ( $engine ) {
		$engine_id_file = $f;
		say "Engine heuristic via file: $engine_id_file" if $verbose;
		say "Engine heuristic result: $engine" if $verbose;
		last;
	}
}

# not FNA, XNA, or MonoGame on 1st pass; check if it could still be Mono
unless ( $engine ) {
	$engine = 'Mono' if get_mono_files or get_mono_files '_';
}

# 2nd Pass: Byte Sequences
unless ( $engine ) {
	say STDERR "Failed to identify game engine on first pass; performing second pass.";
	foreach my $f ( @files ) {
		$engine = IndieRunner::GrandCentral::identify_engine_thorough($f);
		if ( $engine ) {
			$engine_id_file = $f;
			say "Engine heuristic via file: $engine_id_file" if $verbose;
			say "Engine heuristic result: $engine" if $verbose;
			last;
		}
	}
}

unless ( $engine ) {
	say STDERR "No game engine identified. Aborting.";
	exit 1;
}

# XXX: detect bundled dependencies

# setup and build launch command
my $module = "IndieRunner::$engine";
$module->setup();
my @run_cmd = $module->run_cmd( $engine_id_file, $cli_file );

# heuristic for game name
$game_name = goggame_name() unless $game_name;
($game_name) = find_file_magic( '^ELF.*executable', glob '*' ) unless $game_name;
($game_name) = find_file_magic( '^PE32 executable \(console\)', glob '*' ) unless $game_name;
$game_name = 'unknown' unless $game_name;

my $steam_appid = cli_appid() or steam_appid();
my $child_steamlog;
if ( $steam_appid ) {
	say 'Found Steam AppID: ' . $steam_appid if $verbose;
}
$child_steamlog = log_steam_time $steam_appid if cli_log_steam_time();

say "\nLaunching game: $game_name" unless $mode eq 'script';

# print what will be executed; stop here if $dryrun
say join( ' ', @run_cmd );
$mode eq 'run' ? say '' : exit 0;

# Execute @run_cmd and log output
my $merged_out = tee_merged {	# $merged_out combines stdout and stderr
	system( @run_cmd );
};
say '' if $merged_out;

# report if error occurred
if ( $? == 0 ) {
	say 'Application exited without errors' if $verbose;
}
elsif ( $? == -1 ) {
	say "failed to execute: $!";
}
elsif ( $? & 127 ) {
	printf "child process died with signal %d, %s coredump\n",
		( $? & 127 ),  ( $? & 128 ) ? 'with' : 'without';
}
else {
	printf "child process exited with value %d\n", $? >> 8;
}

# store $merged_out in $tmpdir
my $now = strftime "%Y-%m-%d-%H:%M:%S", localtime;
my $logfile = catpath( '', $tmpdir, "${game_name}-${now}.log" );
say "storing logs in $logfile" if ( $merged_out and $verbose );
write_file( $merged_out, $logfile ) if $merged_out;

# XXX: inspect $merged_out

# clean up and exit
kill 'KILL', $child_steamlog if $child_steamlog;
exit;

1;
