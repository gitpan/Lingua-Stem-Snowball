#!/usr/bin/perl

use strict;
use Test::More;
use Lingua::Stem::Snowball qw(:all);

my @lang = stemmers();

plan tests => scalar(@lang) + 9;

foreach my $l (@lang) {
	ok('Lingua::Stem::Snowball', ref Lingua::Stem::Snowball->new(lang => $l));
}

my $s;

$s = Lingua::Stem::Snowball->new(lang => $lang[0]);
ok('Lingua::Stem::Snowball', ref($s));
is($s->lang, $lang[0]);

$s = Lingua::Stem::Snowball->new();
ok('Lingua::Stem::Snowball', ref($s));
is($s->lang, '');
$s->lang($lang[0]);
is($s->lang, $lang[0]);
$s->lang('nothing');
is($s->lang, $lang[0]);
$s->lang(uc($lang[0]));
is($s->lang, $lang[0]);

$s = Lingua::Stem::Snowball->new();
is($s->stem('foo'), undef);
is($s->stem(), undef);
