#! /usr/bin/perl

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use Capture::Tiny ':all';
use Getopt::Long;
use File::Find::Rule;
use FindBin; use lib "$FindBin::Bin/../lib";
use Pod::Usage;

use IndieRunner::FNA;
use IndieRunner::Godot;
use IndieRunner::GrandCentral;

### process config & options ###

my $verbose;	# flags
GetOptions (	"help|h"	=> sub { pod2usage(1) },
		"man"		=> sub { pod2usage(-exitval => 0, -verbose => 2) },
		"verbose|v"	=> \$verbose,
	   )
or pod2usage(2);

### detect game engine ###

my $engine;
my $game_file;
my @files = File::Find::Rule->file()->in( '.' );

# 1st Pass: File Names
foreach my $f ( @files ) {
	$engine = IndieRunner::GrandCentral::identify_engine($f);
	if ( $engine ) {
		$game_file = $f;
		say "Game File: $game_file";
		say "Engine: $engine";
		last;
	}
}

# 2nd Pass: Byte Sequences
unless ( $engine ) {
	say "Failed to identify game engine on first pass; attempting second pass (slower).";
	foreach my $f ( @files ) {
		$engine = IndieRunner::GrandCentral::identify_engine_bytes($f);
		if ( $engine ) {
			$game_file = $f;
			say "Game File: $game_file";
			say "Engine: $engine";
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
$module->setup();
my $run_cmd = $module->run_cmd( $game_file );

### Execute $run_cmd and log results/output ###

say "Run Command: $run_cmd";
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
