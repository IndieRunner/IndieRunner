#! /usr/bin/perl

use strict;
use warnings;
use v5.10;

use Archive::Extract;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON;
use Path::Tiny;
use Readonly;

use IndieRunner::IndieRunner;

Readonly::Scalar my $CONFIG_FILE	=> 'config.json';
# version string examples: '1.8.0_312-b07', '1.8.0_181-b02', '11.0.13+8-1', 17.0.1+12-1
Readonly::Scalar my $JAVA_VER_REGEX	=> '\d{1,2}\.\d{1,2}\.\d{1,2}[_\+][\w\-]+';

my $Os;	

my %Valid_Java_Versions = (
	'openbsd'	=> [
				'1.8.0',
				'11',
				'17',
			   ],
);

sub match_bin_file {
	my $regex		= shift(@_);
	my $file		= shift(@_);
	my $case_insensitive	= defined($_[0]);

	my $out = $1 if ( $case_insensitive ?
			  path($file)->slurp_raw =~ /($regex)/i :
			  path($file)->slurp_raw =~ /($regex)/ );

	return $out;
}

sub get_java_version {
	my $bundled_java_bin;
	my $os_java_version;

	# find bundled java binary, alternatively libjava.so or libjvm.so
	# TODO: make smarter
	$bundled_java_bin = 'jre/bin/java';

	# fetch version string from the $bundled_java_bin
	my $got_version = match_bin_file($JAVA_VER_REGEX, $bundled_java_bin);

	# trim $version_str string to OS JAVA_HOME
	if ( $Os eq 'openbsd' ) {
		# OpenBSD: '1.8.0', '11', '17'
		if (substr($got_version, 0, 2) eq '1.') {
			$os_java_version = '1.8.0';
		}
		else {
			$os_java_version = $got_version =~ /^\d{2}/;
		}
	}
	else {
		die "Unsupported OS: $Os";
	}

	# validate $os_java_version
	unless (grep( /^$os_java_version$/, @{$Valid_Java_Versions{$Os}} )) {
		die ( "No valid Java version found in '$bundled_java_bin': ",
			"$os_java_version"
		    );
	}

	return $os_java_version;
}

sub get_java_home {
	my $java_home;

	if ( $Os eq 'openbsd' ) {
		$java_home = '/usr/local/jdk-' . get_java_version;
	}
	else {
		die "Unsupported OS: $Os";
	}

	if ( -d $java_home ) {
		return $java_home
	}
	else {
		die "failed to get JAVA_HOME directory at $java_home: $!";
	}
}

sub extract_jar {
	my $ae;
	my @class_path = @_;

	foreach my $cp (@class_path) {
		unless ( -f $cp ) {
			say "No classpath $cp to extract.";
			return 0;
		}
		say "Extracting $cp ...";
		$ae = Archive::Extract->new( archive	=> $cp,
					     type	=> 'zip' );
		unless ($ae->extract) {
			say "Couldn't extract $cp";
			return 0;
		}
	}

	return 1;
}

sub replace_managed_framework {
	say "not implemented";
	return 0;
}

sub replace_lib {
	say "\nnot implemented";
	return 0;
}

sub do_setup {
	my @class_path			= @{$_[0]};

	my $bitness			= '64';		# TODO: make smarter
	Readonly::Scalar my $SO_SUFX	=> $bitness . '\.so*';

	my $managed_file_to_test
		= 'com/badlogic/gdx/utils/SharedLibraryLoader.class';

	# has desktop-1.0.jar been extracted?
	unless (-f 'META-INF/MANIFEST.MF') {
		extract_jar(@class_path) or return 0;
	}

	# does libgdx managed code framework support this operating system?
	unless ( match_bin_file($Os, $managed_file_to_test, 1) ) {
		replace_managed_framework or return 0;
	}

	# TODO: are all needed native libraries present?
	say "Checking which libraries are present...";
	my @bundled_libs	= glob( '*' . $SO_SUFX  );
	my ($f, $l);	# f: regular file test, l: symlink test
	foreach my $file (@bundled_libs) {
		print $file;
		($f, $l) = ( -f $file , -l $file );

		# F L: symlink to existing file => everything ok
		# F l: non-symlink file => needs fixing
		# f L: broken symlink => needs fixing
		# f l: no file found (impossible after glob above)
		if ($f and $l) {
			say ' ... ok';
			next;
		}
		else {
			replace_lib($file) or
				die "couldn't set up library: $file";
			say ' ... ok';
		}
	}
	exit;

	return 1;
}

sub run {
	my $config_data;
	my $qx_string;
	my $java_home;
	my $main_class;
	my @class_path;
	my @jvm_env;
	my @jvm_args;
	my @system_args;

	# get OS and OS Java variables
	$Os = IndieRunner::IndieRunner::detectplatform;
	unless ( exists $Valid_Java_Versions{$Os} ) {
		die "OS not recognized: $Os";
	}
	$java_home = get_java_home;

	# slurp and assign config data
	$config_data		= decode_json(path($CONFIG_FILE)->slurp_utf8)
		or die "unable to read config data from $CONFIG_FILE: $!";
	$main_class		= $$config_data{'mainClass'}
		or die "Unable to get configurarion for mainClass: $!";
	@class_path		= $$config_data{'classPath'}
		or die "Unable to get configuration for classPath: $!";
	if ( exists($$config_data{'vmArgs'}) ) {
		@jvm_args	= @{$$config_data{'vmArgs'}};
	}

	do_setup(@class_path) or die "Couldn't set up the game";

	# build command and execute
	# TODO: call JVM directly via PBJ::JNI or Jvm from CPAN; better portability?
	@jvm_env	= (
				"JAVA_HOME=$java_home",
				"PATH=$java_home/bin:\$PATH"
			  );
	@system_args = ( 'env', @jvm_env, 'java', @jvm_args, $main_class );
	say "\nExecuting Java Virtual Machine:";
	say join( ' ', @system_args ) . "\n";
	$qx_string = join( ' ', ( @system_args, '2>&1 > indierun.log' ) );
	qx($qx_string);
	say "Execution completed with exit code " . ($? >> 8);
}

run;
