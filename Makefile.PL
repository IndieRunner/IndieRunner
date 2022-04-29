use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IndieRunner',
    AUTHOR              => q{Thomas Frohwein <tfrohwein@openbsd.org>},
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
