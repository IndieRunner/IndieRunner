use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME                => 'IndieRunner',
    AUTHOR              => q{Thomas Frohwein <thfr@openbsd.org>},
    VERSION_FROM        => 'lib/IndieRunner.pm',
    ABSTRACT_FROM       => 'lib/IndieRunner.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IndieRunner-*' },
);

package MY;
use File::ShareDir::Install 'postamble';
