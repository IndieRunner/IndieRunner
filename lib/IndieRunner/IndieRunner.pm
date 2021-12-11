package IndieRunner::IndieRunner;

use strict;
use warnings;
use version; our $VERSION = qv('0.1.0');

use Config;

sub detectplatform {
	return $Config{qw(osname)};
}

1;
