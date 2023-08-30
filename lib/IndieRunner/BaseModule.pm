package IndieRunner::BaseModule;

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

use strict;
use warnings;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');

sub new ( $class, %args ) {
	my $self = bless { %args }, $class;
	return $self;
}

# getters/setters

=pod

sub cli_file ( $self, @val ) {
	if ( @val ) {
		$self->{cli_file} = shift @val;
	}
	return $self->{cli_file};
}

sub dryrun ( $self, @val ) {
	if ( @val ) {
		$self->{dryrun} = shift @val;
	}
	return $self->{dryrun};
}

sub engine_id_file ( $self, @val ) {
	if ( @val ) {
		$self->{engine_id_file} = shift @val;
	}
	return $self->{engine_id_file};
}

sub gameargs ( $self, @val ) {
	if ( @val ) {
		$self->{gameargs} = shift @val;
	}
	return $self->{gameargs};
}

sub game_name ( $self, @val ) {
	if ( @val ) {
		$self->{game_name} = shift @val;
	}
	return $self->{game_name};
}

sub verbose ( $self, @val ) {
	if ( @val ) {
		$self->{verbose} = shift @val;
	}
	return $self->{verbose};
}

=cut

1;
