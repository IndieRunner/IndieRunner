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

=head1 NAME

IndieRunner::Cmdline - parser for IndieRunner commandline arguments

=cut

use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use base qw( Exporter );
our @EXPORT_OK = qw( init_cli );

=head1 SYNOPSIS

 use IndieRunner::Cmdline;

 # obtain hash for IndieRunner CLI configuration
 my %indierunner_config = IndieRunner::Cmdline::init_cli()

=head1 DESCRIPTION

IndieRunner::Cmdline provides subroutine C<init_cli()> for use by a command-line client to configure IndieRunner.

=cut

use Getopt::Long;
use Pod::Usage;

use constant {
	RIGG_NONE	=> 0,
	RIGG_PERMISSIVE	=> 1,
	RIGG_STRICT	=> 2,
	RIGG_DEFAULT	=> 3,
};

my $dir = '.';
my $dllmap;
my $dryrun;
my $engine;
my $file;
my $game;
my $mode;
my $use_rigg;
my $script;
my $verbosity = 0;

=head1 SUBROUTINES

=head2 init_cli()

Parse the commandline arguments and return a hash with the configuration. See L</OPTIONS> for available flags.

=cut

sub init_cli () {
	Getopt::Long::Configure ("bundling");

=head1 OPTIONS

=over 8

=item B<--help/-h>

Print a brief help message.

=item B<--directory=I<directory>/-d I<directory>>

Switch to I<directory>.

=item B<--dllmap=I<file>/-D I<file>>

For use with Mono/FNA/XNA only: specify custom I<file> with dllmap assignments.

=item B<--dryrun/-n>

Show actions that would be taken, without changing or executing anything.

=item B<--engine=I<engine>/-e I<engine>>

Bypass automatic engine detection. Use with caution.

=item B<--file=I<file>/-f I<file>>

Specify the main game file and bypass autodetection.

=item B<--game=I<game>/-g I<game>>

Bypass automatic game detection and run as I<game>. Use with caution.

=item B<--man/-m>

Print the manual page and exit.

=item B<--norigg>

Disable rigg (only applicable if rigg is available on the system).

=item B<--permissive>

Use permissive unveil in rigg (only applicable if rigg is available on the system).

=item B<--script/-s>

Instead of launching the game, generate a shell script to take all the steps (experimental).

=item B<--strict>

Use strict unveil in rigg (only applicable if rigg is available on the system).

=item B<--usage>

Print short usage information.

=item B<--verbose/-v>

Enable verbose output.

=item B<--version/-V>

Print version.

=cut
	GetOptions (    'help|h'	=> sub { pod2usage(-exitval => 0, -verbose => 1); },
	                'directory|d=s'	=> \$dir,
	                'dllmap|D=s'	=> \$dllmap,
			'dryrun|n'	=> \$dryrun,
			'engine|e=s'	=> \$engine,
			'file|f=s'	=> \$file,
			'game|g=s'	=> \$game,
			'man|m'		=> sub { pod2usage(-exitval => 0,
			                                     -verbose => 2, ); },
			'norigg'	=> sub { $use_rigg = RIGG_NONE; },
			'permissive'	=> sub { $use_rigg = RIGG_PERMISSIVE; },
			'script|s'	=> \$script,
			'strict'	=> sub { $use_rigg = RIGG_STRICT; },
			'usage'		=> sub { pod2usage(-exitval => 0,
			                                   -verbose => 0, ); },
			'verbose|v+'	=> \$verbosity,
			'version|V'	=> sub { say $VERSION; exit; },	# XXX: $VERSION from which module or script?
		   )
	or pod2usage(2);

=item B<-- I<game arguments>>

Arguments after C<--> are passed to the invocation of the game itself, via the key C<game_args>. Example: C<-windowed -skipintro>

=back

=cut

	# if rigg is not available, set use_rigg to RIGG_NONE
	if ( system( 'which rigg > /dev/null 2>&1' ) ) {
		say 'rigg not found. Continuing without it.' if $verbosity;
		$use_rigg = RIGG_NONE;
	}

=head1 RETURN VALUE

init_cli returns a hash with the following keys:
  dir
  dllmap
  dryrun
  engine
  file
  game
  game_args
  use_rigg
  script
  verbosity

=cut
	# keep this in sync with %INIT_ATTRIBUTES_DEFAULTS in IndieRunner.pm
	return {
		dir		=> $dir,
		dllmap		=> $dllmap,
		dryrun		=> $dryrun,
		engine		=> $engine,
		file		=> $file,
		game		=> $game,
		game_args	=> \@ARGV,
		use_rigg	=> $use_rigg,
		script		=> $script,
		verbosity	=> $verbosity,
	};
}

1;

__END__


=head1 SEE ALSO

L<Getopt::Long>
L<IndieRunner>
L<Pod::Usage>
L<indierunner>

=head1 AUTHOR

Thomas Frohwein E<lt>thfr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022-2024 by Thomas Frohwein E<lt>thfr@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it under the ISC license.

=cut
