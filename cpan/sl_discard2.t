#!/usr/bin/perl
# Copyright 2015 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

# Tests of the SLIF's discard events

use 5.010;
use strict;
use warnings;
use Test::More tests => 4;
use English qw( -no_match_vars );
use Scalar::Util;

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $null_grammar = Marpa::R2::Scanless::G->new(
    {   bless_package => 'My_Nodes',
        source        => \(<<'END_OF_SOURCE'),
:default ::= action => [g1start,g1length,name,values]
discard default = event => :symbol=off
lexeme default = action => [ g1start, g1length, start, length, value ]
    latm => 1

Script ::=
:discard ~ whitespace event => ws
whitespace ~ [\s]
END_OF_SOURCE
    }
);


for my $input ( q{}, ' ', '  ', '   ' ) {
my $recce = Marpa::R2::Scanless::R->new( { grammar => $null_grammar },
# { trace_terminals => 99 }
);

my $length = length $input;
say "Length = $length";
my $pos = $recce->read(\$input);

my @actual_events = ();

READ: while (1) {


    EVENT:
    for my $event ( @{ $recce->events() } ) {
        my ($name, @other_stuff) = @{$event};
        say STDERR 'Event received!!! -- ', Data::Dumper::Dumper($event);
        push @actual_events, $event;
    }

    last READ if $pos >= $length;
    $pos = $recce->resume($pos);
} ## end READ: while (1)

my $actual_events = join q{ }, map { $_->[0], $_->[-1] } @actual_events;
my $expected_events = join q{ }, (('ws 0') x $length);
Test::More::is($actual_events, $expected_events, "Test of $length discarded spaces");

my $value_ref = $recce->value();
die "No parse was found\n" if not defined $value_ref;

my $result = ${$value_ref};
say Data::Dumper::Dumper($result);
}

# vim: expandtab shiftwidth=4:
