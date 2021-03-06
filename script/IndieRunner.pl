#! /usr/bin/perl

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
use File::Spec::Functions qw( splitpath );
use FindBin; use lib "$FindBin::Bin/../lib";

use IndieRunner::Cmdline qw( cli_dryrun cli_file cli_verbose init_cli );
use IndieRunner::FNA;
use IndieRunner::Godot;
use IndieRunner::GrandCentral;
use IndieRunner::HashLink;
use IndieRunner::Mono qw( get_mono_files );
use IndieRunner::MonoGame;
use IndieRunner::XNA;

# process config & options
init_cli;
my $cli_file	= cli_file;
my $dryrun	= cli_dryrun;
my $verbose	= cli_verbose;

# if $cli_file contains directory, switch to that directory
if ( $cli_file ) {
	die "No such file or directory: $cli_file" unless ( -e $cli_file );
	if ( -d $cli_file ) {
		chdir $cli_file;
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
my @files = glob '*';

# 1st Pass: File Names
foreach my $f ( @files ) {
	$engine = IndieRunner::GrandCentral::identify_engine($f);
	if ( $engine ) {
		$engine_id_file = $f;
		say "Engine identified from file: $engine_id_file" if $verbose;
		say "Engine: $engine" if $verbose;
		last;
	}
}

# detect XNA
if ( -d '_CommonRedist/XNA' || -f 'xnafx40_redist.msi' ) {
	$engine = 'XNA';
	$engine_id_file = '';
	say "Engine: $engine" if $verbose;
}

# not FNA, XNA, or MonoGame on 1st pass; check if it could still be Mono
unless ( $engine ) {
	$engine = 'Mono' if get_mono_files;
}

# 2nd Pass: Byte Sequences
unless ( $engine ) {
	say "Failed to identify game engine on first pass; attempting second pass (slower).";
	foreach my $f ( @files ) {
		$engine = IndieRunner::GrandCentral::identify_engine_bytes($f);
		if ( $engine ) {
			$engine_id_file = $f;
			say "Engine identified from file: $engine_id_file" if $verbose;
			say "Engine: $engine" if $verbose;
			last;
		}
	}
}

unless ( $engine ) {
	say "No game engine identified. Aborting.";
	exit 1;
}

# XXX: detect bundled dependencies

# setup and build launch command
my $module = "IndieRunner::$engine";
$module->setup();
my @run_cmd = $module->run_cmd( $engine_id_file, $cli_file );

# Execute @run_cmd and log output
say 'Launching child process:' unless $dryrun;
say join( ' ', @run_cmd );
$dryrun ? exit 0 : say '';
my ($stdout, $stderr) = tee {
	system( @run_cmd );
};

# report if error occurred
say '';
if ( $? == 0 ) {
	say 'Application exited without errors' if $verbose;
}
elsif ( $? == -1 ) {
	say "failed to execute: $!";
}
elsif ( $? & 127 ) {
	printf "child died with signal %d, %s coredump\n",
		( $? & 127 ),  ( $? & 128 ) ? 'with' : 'without';
}
else {
	printf "child exited with value %d\n", $? >> 8;
}

# XXX: inspect $stdout, $stderr

# clean up (if needed) and exit
exit;

__END__

=head1 NAME

IndieRunner - Launch your indie games on more platforms

=head1 SYNOPSIS

IndieRunner [options] [file]

=head1 OPTIONS

=over 8

=item B<--dryrun/-d>

Show actions that would be taken, without changing or executing anything.

=item B<--help/-h>

Print a brief help message.

=item B<--man/-m>

Print the manual page and exits.

=item B<--usage>

Print short usage information.

=item B<--verbose/-v>

Enable verbose output.

=item B<--version>

Print version.

=item B<file>

Specify the main game file and bypass autodetection. Optional.

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
