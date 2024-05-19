use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME                => 'IndieRunner',
    AUTHOR              => q{Thomas Frohwein <thfr@cpan.org>},
    LICENSE		=> 'open_source',
    MIN_PERL_VERSION	=> ' 5.36.0',
    VERSION_FROM        => 'bin/indierunner',
    ABSTRACT_FROM       => 'bin/indierunner',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'				=> 0,
        'Config'			=> 0,
        'Fcntl'				=> 0,
        'File::Copy'			=> 0,
        'File::Copy::Recursive'		=> 0,
        'File::Find::Rule'		=> 0,
        'File::LibMagic'		=> 0,
        'File::Path'			=> 0,
        'File::Share'			=> 0,
        'File::Spec::Functions'		=> 0,
        'FindBin'			=> 0,
        'Getopt::Long'			=> 0,
        'JSON'				=> 0,
        'List::Util'			=> 0,
        'Path::Tiny'			=> 0,
        'Pod::Coverage'			=> 0,
        'Pod::Usage'			=> 0,
        'POSIX'				=> 0,
        'Test::CheckManifest'		=> 0,
        'Test::More' 			=> 0,
        'Test::Pod'			=> 0,
        'Test::Pod::Coverage'		=> 0,
        'Test::Simple'			=> 0,
        'Text::Glob'			=> 0,
    },
    EXE_FILES => [
        'bin/indierunner',
    ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IndieRunner-*' },
);

package MY;
use File::ShareDir::Install 'postamble';
