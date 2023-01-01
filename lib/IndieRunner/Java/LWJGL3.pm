package IndieRunner::Java::LWJGL3;

# Copyright (c) 2022 Thomas Frohwein
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use version 0.77; our $VERSION = version->declare( 'v0.0.1' );
use strict;
use warnings;
use v5.10;
use Carp qw( cluck );

use base qw( Exporter );
our @EXPORT_OK = qw( get_java_version_preference );

use Readonly;

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );
use IndieRunner::Platform qw( get_os );

# if LWJGL3 libs are built with Java 11, they fail to run with 1.8:
# java.lang.NoSuchMethodError: java.nio.ByteBuffer.position(I)Ljava/nio/ByteBuffer;
Readonly::Hash my %LWJGL3_JAVA_VERSION => (
	'openbsd'	=> '11',
	);

Readonly::Hash my %LWJGL3_DIR => (
	'openbsd'	=> '/usr/local/share/lwjgl3',
	);

sub get_java_version_preference {
	return $LWJGL3_JAVA_VERSION{ get_os() };
}

sub add_classpath {
	return glob( $LWJGL3_DIR{ get_os() } . '/*.jar' );
}

sub setup {
	my ($self) = @_;

	# empty
}

1;
