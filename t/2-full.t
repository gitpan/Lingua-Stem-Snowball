#!/usr/bin/perl

use strict;
use Test::More;
use Lingua::Stem::Snowball qw(:all);
use locale;   
use POSIX qw(locale_h);

my %ok_lang = map { $_ => 1 } (qw(da de dk en es fi fr it no pt sv));

# We skip if we don't have the locale
my $locales;
foreach my $lang (keys %ok_lang) {
	my $old_locale = setlocale(LC_CTYPE);
	my $ret = setlocale(LC_CTYPE, "$lang\_".uc($lang));
	my $locale = defined($ret) ? "$lang\_".uc($lang) : '';
	unless ($locale) {
		my $ret = setlocale(LC_CTYPE, $lang);
		$locale = defined($ret) ? $lang : '';
	}
	if ($locale) {
		$locales->{$lang} = $locale;
	} else {
		delete $ok_lang{$lang};
	}
}

my $tests_file = "stemmers_src/tests.txt";

my $tests = 0;
my ($words, $results);
open(I, "<$tests_file");
while (<I>) {
	s/\s+$//g;
	my ($lang, $test, $result) = split /\|/;
	if ($ok_lang{$lang}) {
		push @{$words->{$lang}}, $test;
		push @{$results->{$lang}}, $result;
		$tests++;
	}
}
close(I);

plan tests => 3 * $tests + 2 * scalar(keys %ok_lang);

my $last_lang = '';
my $stem = Lingua::Stem::Snowball->new();
open(I, "<$tests_file");
while (<I>) {
	s/\s+$//g;
	my ($lang, $test, $result) = split /\|/;

	next unless $ok_lang{$lang};

	if ($lang ne $last_lang) {
		$stem->lang($lang);
		$stem->locale($locales->{$lang});
	}

	is($stem->stem($test), $result);
	is(stem($lang, $test), $result, $locales->{$lang});
	is($stem->stem(uc($test)), $result);

	$last_lang = $lang;
}
close(I);

foreach my $lang (keys %ok_lang) {
	$stem->lang($lang);
	$stem->locale($locales->{$lang});
	my @results = $stem->stem($words->{$lang});
	ok(eq_array(\@results, \@{$results->{$lang}}));

	my @results1 = stem($lang, $words->{$lang});
	ok(eq_array(\@results1, \@{$results->{$lang}}));
}
