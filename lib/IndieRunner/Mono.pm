package IndieRunner::Mono;

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');

use base qw( Exporter );
our @EXPORT_OK = qw( $BIN remove_mono_files );

use Carp;
use Readonly;

Readonly::Scalar our $BIN => 'mono';

Readonly::Array my @GLOBS2REMOVE => (
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
	my @files2remove;

	foreach my $g ( @GLOBS2REMOVE ) {
		push( @files2remove, glob( $g ) );
	}
	unlink @files2remove;
}

1;
