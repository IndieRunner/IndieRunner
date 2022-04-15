package IndieRunner::IndieRunner;

use strict;
use warnings;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use Config;

sub detectplatform {
	return $Config{qw(osname)};
}

1;
