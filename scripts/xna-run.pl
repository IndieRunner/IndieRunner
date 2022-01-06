#! /usr/bin/perl

use strict;
use warnings;
use v5.10;

use File::Basename;
use File::Spec::Functions qw( catdir splitdir splitpath );
use Readonly;

Readonly::Scalar my $FNAIFY		=>
	'fnaify -y';
Readonly::Scalar my $NOTFOUND_REGEX	=>
	'System\.IO\.[A-Za-z]+NotFoundException: Could not find [a-z ]+"([^"]*)';

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
		if ( -e $f and lc($f) eq lc($wrong_file) ) {
			return $f;
		}
	}

	return '';
}

sub query_rerun {
	print 'Run again? [y] ';
	my $input = <STDIN>;
	chomp $input;
	if ( $input eq '' or lc($input) eq 'y') {
		return 1;
	}
	return 0;
}

sub fix_notfound_file {
	my $notfound_file = shift(@_);

	my $found_file;
	my @fullpath;
	my @path;

	# break down the path into components
	(my $volume, my $directories, my $file) = splitpath( $notfound_file );
	@fullpath = ( splitdir( $directories ), $file );

	# test path one component at a time and fix with symlink
	foreach my $p (@fullpath) {
		push ( @path, $p );
		next if ( -e catdir(@path) );
		print 'attempting to fix path for: ' . catdir(@path);
		if ( $found_file = get_right_file( catdir(@path) ) ) {
			create_symlink( $found_file, catdir(@path) );
			say '... done!';
			return 1;
		}
		say '... failed!';
		last;
	}

	return 0;
}

sub run {
	my $found_file;
	my $notfound_file;
	my $output;
	my $rerun;

	do {
		$rerun = 0;

		# run fnaify and catch output
		$output = qx($FNAIFY 2>&1);

		# if there was a FileNotFoundException, offer a fix
		($notfound_file) = $output =~ /$NOTFOUND_REGEX/m;
		if ( $notfound_file ) {
			say "Game looking for non-existent file: $notfound_file";
			if ( fix_notfound_file($notfound_file) ) {
				$rerun = query_rerun;
			}
			else {
				die 'Can\'t fix path. Aborting.';
			}
		}
	} while ($rerun);

	say "Last Output:\n$output";
}

run;
