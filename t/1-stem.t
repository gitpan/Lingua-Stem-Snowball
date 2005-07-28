#!/usr/bin/perl

use strict;
use Test::More;
use Lingua::Stem::Snowball qw(:all);

my @lang = stemmers();

plan tests => scalar(@lang) + 17;

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

# Test for bug #7510
is(stem('fr', 'été'), 'été');

# Tests for bug #7509
$s = Lingua::Stem::Snowball->new();
ok('Lingua::Stem::Snowball', ref($s));
is($s->lang, '');
$s->lang('nothing');
is($@, "Language 'nothing' does not exist");

# Test for mixed case words
is(stem('fr', 'AIMERA'), stem('fr', 'aimera'));

# Test for bug #13900
$s = Lingua::Stem::Snowball->new(lang => 'en');
my @stemmable = ('', undef, 'foo', 'bar', '');
my @stemmed = $s->stem(\@stemmable);
is(scalar(@stemmable), scalar(@stemmed), "don't strip empty array elements");

# Test for ticket #13898
$s = Lingua::Stem::Snowball->new(lang => 'en');
@stemmable = ('foo', 'ranger\'s', 'bar');
my @stemmed_ok = ('foo', 'ranger', 'bar');
$s->strip_apostrophes(1);
@stemmed = $s->stem(\@stemmable);
ok(eq_array(\@stemmed_ok, \@stemmed), "apostrophe s");

$s = Lingua::Stem::Snowball->new(lang => 'fr');
@stemmable = ('l\'article', 'presse');
@stemmed_ok = ('articl', 'press');
$s->strip_apostrophes(1);
@stemmed = $s->stem(\@stemmable);
ok(eq_array(\@stemmed_ok, \@stemmed), "apostrophe s");
