use strict;
use warnings;
use v5.36;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME                => 'IndieRunner',
    AUTHOR              => q{Thomas Frohwein <thfr@cpan.org>},
    VERSION_FROM        => 'script/indierunner',
    ABSTRACT_FROM       => 'lib/IndieRunner.pod',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    EXE_FILES => [
        'script/indierunner',
    ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IndieRunner-*' },
);

package MY;
use File::ShareDir::Install 'postamble';
