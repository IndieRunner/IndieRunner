use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME                => 'IndieRunner',
    AUTHOR              => q{Thomas Frohwein <thfr@cpan.org>},
    LICENSE		=> 'open_source',
    MIN_PERL_VERSION	=> '5.36.0',
    VERSION_FROM        => 'lib/IndieRunner.pm',
    ABSTRACT_FROM       => 'lib/IndieRunner.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'				=> 0,
	'Class::Inspector'		=> '1.36',
        'Config'			=> 0,
        'Fcntl'				=> 0,
        'File::Copy'			=> 0,
        'File::Copy::Recursive'		=> 0,
	'File::Find::Rule'		=> '0.34',
	'File::LibMagic			=> '1.23',
	'File::LibMagic::Constants'	=> '1.23',
        'File::Path'			=> 0,
	'File::Share'			=> '0.27',
	'File::ShareDir'		=> '1.118',
        'File::Spec::Functions'		=> 0,
        'FindBin'			=> 0,
        'Getopt::Long'			=> 0,
	'JSON'				=> '4.10',
        'List::Util'			=> 0,
	'Number::Compare'		=> '0.03',
	'Path::Tiny'			=> '0.144',
	'PerlIO::utf8_strict'		=> '0.007',
        'Pod::Coverage'			=> 0,
        'Pod::Usage'			=> 0,
        'POSIX'				=> 0,
	'Readonly'			=> '2.05',
        'Test::CheckManifest'		=> 0,
        'Test::More' 			=> 0,
        'Test::Pod'			=> 0,
        'Test::Pod::Coverage'		=> 0,
        'Test::Simple'			=> 0,
	'Text::Glob'			=> '0.11',
    },
    EXE_FILES => [
        'bin/indierunner',
    ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IndieRunner-*' },
);

package MY;
use File::ShareDir::Install 'postamble';
