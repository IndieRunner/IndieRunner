package IndieRunner::Mono;

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( $BIN );

use Carp;
use Readonly;

Readonly::Scalar our $BIN => 'mono';

Readonly::Array my @FILES2REMOVE => (
	'I18N{,.*}.dll',
	'Microsoft.*.dll',
	'Mono.*.dll',
	'System{,.*}.dll',
	'libMonoPosixHelper.so*',
	'monoconfig',
	'monomachineconfig',
	'mscorlib.dll',
	);

sub remove_mono_files {
	foreach my $g ( @FILES2REMOVE ) {
		say join( ' ', glob( $g ) ) || 'NONE';
	}
}

1;
