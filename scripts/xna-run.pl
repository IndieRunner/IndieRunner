#! /usr/bin/perl

use strict;
use warnings;
use v5.10;

use File::Basename;
use Readonly;

Readonly::Scalar my $FNAIFY		=>
	'/home/thfr/cvs/projects/fnaify/fnaify -y';
Readonly::Scalar my $NOFILE_REGEX	=>
	'^\[ERROR].*System\.IO\.FileNotFoundException.*Could not find file "([^"]*)';

sub create_symlink {
	my $oldfile	= basename(shift(@_));
	my $newfile	= shift(@_);

	# TODO:	check if platform supports symbolic links
	#	https://perldoc.perl.org/perlport#symlink
	symlink($oldfile, $newfile) or die "failed to symlink: $!";
}

sub get_right_file {
	my $wrong_file = shift(@_);

	my @files = glob( dirname($wrong_file) . '/*' );
	foreach my $f (@files) {
		if ( -f $f and lc($f) eq lc($wrong_file) ) {	# -f skip symlinks
			return $f;
		}
	}

	return '';
}

sub run {
	my $existent_file;
	my $input;
	my $nonexistent_file;
	my $output;
	my $rerun;

	do {
		$input = '';
		$rerun = 0;

		# run fnaify and catch output
		$output = qx($FNAIFY 2>&1);

		# if there was a FileNotFoundException, offer a fix
		($nonexistent_file) = $output =~ /$NOFILE_REGEX/m;
		if ( $nonexistent_file ) {
			say "Game looking for non-existent file: $nonexistent_file";
			$existent_file = get_right_file($nonexistent_file);

			if ( $existent_file ) {
				say 'Symlinking to: ' . basename($existent_file);
				create_symlink($existent_file, $nonexistent_file);

				print 'Run again after symlink created? [y] ';
				$input = <STDIN>;
				chomp $input;
				if ( $input eq '' or lc($input) eq 'y') {
					$rerun = 1;
				}
			}
			else {
				say '... no matching file found.';
			}
		}
	} while ($rerun);
}

run;
