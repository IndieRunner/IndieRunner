#! /usr/bin/perl

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use Capture::Tiny ':all';
use Getopt::Long;
use FindBin; use lib "$FindBin::Bin/../lib";
use Pod::Usage;

use IndieRunner::FNA;
use IndieRunner::Godot;
use IndieRunner::GrandCentral;
use IndieRunner::Mono qw( get_mono_files );
use IndieRunner::MonoGame;

### process config & options ###

my ($dryrun, $verbose);	# flags
GetOptions (	"help|h"	=> sub { pod2usage(1) },
		"dryrun|d"	=> \$dryrun,
		"man"		=> sub { pod2usage(-exitval => 0, -verbose => 2) },
		"verbose|v"	=> \$verbose,
	   )
or pod2usage(2);
my $game_file = $ARGV[0];

# check that $game_file exists (can be globbed)
if ( $game_file ) {
	unless ( -f $game_file and ( $game_file eq glob( $game_file ) ) ) {
		say "No such file: $game_file";
		exit 1;
	}
}

### detect game engine ###

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

# not FNA or MonoGame on 1st pass; check if it could still be Mono
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

### detect bundled dependencies ###

### setup (if needed) and build the launch command ###

my $module = "IndieRunner::$engine";
$module->setup() unless $dryrun;
my $run_cmd = $module->run_cmd( $engine_id_file, $game_file );

### Execute $run_cmd and log results/output ###

say 'Run Command:' unless $dryrun;
print "\t" unless $dryrun;
say "$run_cmd";
exit 0 if $dryrun;
my ($stdout, $stderr) = tee {
	system( '/bin/sh', '-c', $run_cmd );
};
my $err_exit = $? >> 8;

### clean up ###

exit;

__END__

=head1 NAME

IndieRunner - Launch your indie games on more platforms

=head1 SYNOPSIS

IndieRunner [options] [game file]

=head1 OPTIONS

=over 8

=item B<-dryrun/-d>

Show command that would be run, but don't execute it. Skips setup, too.

=item B<-help/-h>

Print a brief help message.

=item B<-man/-m>

Prints the manual page and exits.

=item B<-verbose/-v>

Enable verbose output.

=item B<game file>

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
