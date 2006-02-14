#!/usr/bin/perl

use strict;
use Test::More tests => 8484;
use Lingua::Stem::Snowball qw( stem );
use File::Spec;

my @languages = qw( en da de es fi fr it nl no pt ru sv );
my $stemmer   = Lingua::Stem::Snowball->new();

for my $iso (@languages) {
    my ( @before, @after );
    my $encoding;

    # set language
    $stemmer->lang($iso);

    # test ISO-8859-1 / KOI8-R vocab
    $encoding = $iso eq 'ru' ? 'KOI8-R' : 'ISO-8859-1';
    my $default_enc_voc_path
        = File::Spec->catfile( 't', 'test_voc', "$iso.default_enc" );
    open( my $default_enc_voc_fh, '<', $default_enc_voc_path )
        or die "Couldn't open file '$default_enc_voc_path' for reading: $!";
    $stemmer->encoding($encoding);
    while (<$default_enc_voc_fh>) {
        chomp;
        my ( $raw, $expected ) = split;
        push @before, $raw;
        push @after,  $expected;
        test_singles( $raw, $expected, $iso, $encoding );
    }
    test_arrays( \@before, \@after, $iso, $encoding );

    # test UTF-8 vocab
    $encoding = 'UTF-8';
    @before   = ();
    @after    = ();
    my $utf8_voc_path = File::Spec->catfile( 't', 'test_voc', "$iso.utf8" );
    open( my $utf8_voc_fh, '<:utf8', $utf8_voc_path )
        or die "Couldn't open file '$utf8_voc_path' for reading: $!";
    $stemmer->encoding($encoding);
    while (<$utf8_voc_fh>) {
        chomp;
        my ( $raw, $expected ) = split;
        push @before, $raw;
        push @after,  $expected;
        test_singles( $raw, $expected, $iso, $encoding );
    }
    test_arrays( \@before, \@after, $iso, $encoding );

}

sub test_singles {
    my ( $raw, $expected, $iso, $encoding ) = @_;

    my $got = $stemmer->stem($raw);
    is( $got, $expected, "$iso \$s->stem(\$raw)" );

    if ( $encoding ne 'UTF-8' ) {
        $got = stem( $iso, $raw );
        is( $got, $expected, "$iso stem(\$lang, \$raw)" );
    }

    $got = $stemmer->stem( uc($raw) );
    is( $got, $expected, "$iso \$s->stem(uc(\$raw))" );

    $got = [$raw];
    $stemmer->stem_in_place($got);
    is( $got->[0], $expected, "$iso \$s->stem_in_place(\$raw)" );
}

sub test_arrays {
    my ( $raw, $expected, $iso, $encoding ) = @_;

    my @got = $stemmer->stem($raw);
    is_deeply( \@got, $expected, "$iso \$s->stem(\@raw)" );

    if ( $encoding ne 'UTF-8' ) {
        @got = stem( $iso, $raw );
        is_deeply( \@got, $expected, "$iso stem(\$lang, \@raw)" );
    }

    my @uppercased = map {uc} @$raw;
    @got = $stemmer->stem( \@uppercased );
    is_deeply( \@got, $expected, "$iso \$s->stem(\@raw) (uc'd)" );

    @got = @$raw;
    $stemmer->stem_in_place( \@got );
    is_deeply( \@got, $expected, "$iso \$s->stem_in_place(\@raw)" );
}

