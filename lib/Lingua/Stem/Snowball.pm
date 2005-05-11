package Lingua::Stem::Snowball;

use strict;
use Carp;
use Exporter;
use locale;   
use POSIX qw(locale_h);
use vars qw($VERSION @ISA @EXPORT_OK $AUTOLOAD %EXPORT_TAGS);
@ISA = qw(Exporter);

$VERSION = '0.91';

%EXPORT_TAGS = ('all' => [qw(
	stemmers stem
)]);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

require XSLoader;
XSLoader::load('Lingua::Stem::Snowball', $VERSION);

sub AUTOLOAD {
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, (@_ and $_[0] =~ /^\d+$/) ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
                croak "Your vendor has not defined Lingua::Stem::Snowball macro $constname";
        }
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

sub _get_lang {
	my ($lang) = @_;

	my $lang_id = Lingua::Stem::Snowball::get_stemmer_id($lang);

	if ($lang_id < 0) {
		if ($lang_id == -1) {
			$@ = "Language '$lang' does not exist";
		} elsif ($lang_id == -2) {
			$@ = "Can't call init for language '$lang'";
		} else {
			# We cannot be here!
			$@ = "Unknown error for language '$lang'";
		}
		$lang = '';
		$lang_id = 0;
	}

	return ($lang, $lang_id);
}

sub lang {
	my ($self, $lang) = @_;

	if ($lang) {
		my ($new_lang, $lang_id) = _get_lang($lang);
		if ($new_lang) {
			$self->{LANG} = $new_lang;
			$self->{LANG_ID} = $lang_id;
		}
	}

	return $self->{LANG};
}

sub locale {
	my ($self, $locale) = @_;

	if ($locale) {
		$self->{LOCALE} = $locale;
	}

	return $self->{LOCALE};
}

sub new {
	my ($class, %opt) = @_;

	$class = ref($class) || $class;
	my $self = {};

	$@ = '';
	if ($opt{lang}) {
		my ($new_lang, $lang_id) = _get_lang($opt{lang});
		if ($new_lang) {
			$self->{LANG} = $new_lang;
			$self->{LANG_ID} = $lang_id;
		}
	} else {
		$self->{LANG} = ''; 
		$self->{LANG_ID} = 0;
	}

	$self->{LOCALE} = undef;
	$self->{LOCALE} = $opt{locale} if defined $opt{locale};

        bless ($self, $class);

        return $self;
}

sub stem {
	my $self = shift;

	my ($words, $rr);
	if (UNIVERSAL::isa($self, 'HASH')) {
		($words, $rr) = @_;
	} else {
		my $lang = $self;
		my $locale;
		($words, $locale, $rr) = @_;

		$self = Lingua::Stem::Snowball->new(lang => $lang, locale => $locale);
	}

	return undef if (!$self->{LANG});
	return undef if (!ref($words) and !length($words));

	my $old_locale;
	if (defined $self->{LOCALE}) {
		$old_locale = setlocale(LC_CTYPE);
		my $ret = setlocale(LC_CTYPE, $self->{LOCALE});
		warn "Can't set locale $self->{LOCALE}" if (!defined($ret));
	}

	my @lexems;
	my $res;
	my $lexem;
	if (ref($words)) {
		foreach my $word (@$words) {
			next unless $word;
			$res = Lingua::Stem::Snowball::do_stem($self->{LANG_ID}, $word, $lexem);
			die "Error in Lingua::Stem::Snowball::do_stem" if ($res < 0);
			push @lexems, $lexem;
		}
	} else {
		$res = Lingua::Stem::Snowball::do_stem($self->{LANG_ID}, $words, $lexem);
		die "Error in Lingua::Stem::Snowball::do_stem" if ($res < 0);
		push @lexems, $lexem;
	}

	if (defined $self->{LOCALE}) {
		setlocale(LC_CTYPE, $old_locale);
	}

	$$rr = $res if (ref $rr);

	return wantarray ? @lexems : $lexems[0];
}

sub stemmers {
	my @lang;

	Lingua::Stem::Snowball::get_stemmer_list(\@lang);

	return @lang;
}

# Deprecated
sub snowball {
	my ($lang, $word, $locale, $rr) = @_;

	stem($lang, $word, $locale, $rr);
}
# deprecated

sub DESTROY {
}

1;

__END__

=head1 NAME

Lingua::Stem::Snowball - Perl interface to Snowball stemmers. 

=head1 SYNOPSIS

  use  Lingua::Stem::Snowball;

  my @lang = stemmers();

OO interface:

  my $lang = 'en';
  my $dict = Lingua::Stem::Snowball->new(lang => $lang);
  # Test if $lang is correct
  die $@ if ($@);
  my $locale = 'C'; 

  my $dict = Lingua::Stem::Snowball->new(lang => $lang, locale => $locale);
  my $lemm = $dict->stem($word);
  my $lemm = $dict->stem($word, \$is_stemmed);

  my $dict = Lingua::Stem::Snowball->new();
  $dict->lang($lang);
  $dict->locale($locale);
  my $lemm = $dict->stem($word);
  my @lemm = $dict->stem(\@words);

Plain interface:

  my $lemm = stem($lang, $word);
  my $lemm = stem($lang, $word, $locale);
  my $lemm = stem($lang, $word, $locale, \$is_stemmed);

=head1 DESCRIPTION

This module provides unified perl interface to Snowball stemmers
(http://snowball.tartarus.org) and virtually supports various
languages. It's written using C for high performance and provides
OO and plain interfaces.

The motivation of developing this module was to provide a generic access to 
stemming algorithms for OpenFTS project - full text search engine
(http://openfts.sourceforge.net).

The module is very similar with Lingua::Stem. But Lingua::Stem is written in pure perl
whereas Lingua::Stem::Snowball is an XS version of the snowball stemmers.

The following stemmers are available (as of Lingua::Stem 0.70):

  |------------------------------|
  | Language	 | L:S 	 | L:S:S | 
  |------------------------------|
  | English	 | y	 | y	 | 
  | French	 | y	 | y	 | 
  | Spanish	 | n	 | y	 | 
  | Portuguese	 | y	 | y	 | 
  | Italian	 | y	 | y	 | 
  | German	 | y	 | y	 | 
  | Dutch	 | n	 | y	 | 
  | Swedish	 | y	 | y	 | 
  | Norwegian	 | y	 | y	 | 
  | Danish	 | y	 | y	 | 
  | Russian	 | n	 | y	 | 
  | Finnish	 | n	 | y	 | 
  | Galician	 | y	 | n	 | 
  |------------------------------|

Here is a little benchmark with examples files from the snowball distribution (with no cache):

  |---------------------------------------------------|
  | Language | Unique |          Time (s)             | 
  |          | words  | L:S:S | L:S:S | L:S   | L:S:S | 
  |          |        | @     | $     | @     | $     | 
  |---------------------------------------------------|
  | DA       | 23829  | 0.5   | 1.1   | 7.3   | 14.2  | 
  | DE       | 35033  | 0.9   | 1.9   | 64.3  | 73.5  | 
  | EN       | 30428  | 0.7   | 1.5   | 2.5   | 8.8   | 
  | FR       | 20403  | 0.6   | 1.1   | 182.7 | 188.0 | 
  | IT       | 35494  | 1.0   | 2.0   | 345.6 | 350.2 | 
  | NO       | 20628  | 0.4   | 1.0   | 14.3  | 20.6  | 
  | PT       | 32016  | 0.8   | 1.7   | 405.6 | 414.8 | 
  | SV       | 30623  | 0.0   | 0.5   | 15.9  | 25.6  | 
  |---------------------------------------------------|

Here is the same benchmark with all unique words found in the bible:

  |---------------------------------------------------|
  | EN       | 12718  | 0.3   | 0.7   | 1.0   | 3.6   | 
  |---------------------------------------------------|

=head1 METHODS

=over 4

=item $dict = Lingua::Stem::Snowball->new

Creates a new instance of the stemmer.

The constructor takes hash style parameters. The following parameters are recognized:

lang: language (ISO code).

locale: locale.

=item my $stemmed = $dict->stem($word)

Returns the stemmed word for $word.

=item my @stemmed = $dict->stem(\@word)

Returns an array of the stemmed words contained in @word.

=item $dict->lang([$lang])

Accessor for the lang parameter. If there is no stemmer for $lang,
the language is not changed.

=item $dict->locale([$locale])

Accessor for the locale parameter.

=item stemmers()

Returns a list of all available languages with a stemmer.

=back

=head1 REQUESTS & BUGS

Please report any requests, suggestions or bugs via the RT bug-tracking system 
at http://rt.cpan.org/ or email to bug-Lingua-Stem-Snowball\@rt.cpan.org. 

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Stem-Snowball is the RT queue for Lingua::Stem::Snowball.
Please check to see if your bug has already been reported. 

=head1 COPYRIGHT

Copyright 2004

Currently maintained by Fabien Potencier, fabpot@cpan.org
Original authors Oleg Bartunov, oleg@sai.msu.su, Teodor Sigaev, teodor@stack.net

This software may be freely copied and distributed under the same
terms and conditions as Perl.

Snowball files and stemmers are covered by the BSD license.

=head1 SEE ALSO

http://snowball.tartarus.org, Lingua::Stem

=cut


