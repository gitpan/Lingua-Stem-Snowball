#!/usr/bin/perl

# Tests for bug #7510

use strict;
use Test::More tests => 4;
use lib qw(t);
BEGIN {
	use_ok('MyStem');
};

my $s = MyStem->new(lang => 'fr');
ok('MyStem', ref($s));

my $lemm = $s->stem('été');
is($lemm, 'été');

$lemm = $s->stem('aimant');
is($lemm, 'aim');
