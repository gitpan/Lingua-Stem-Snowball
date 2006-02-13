#!/usr/bin/perl

use strict;
use Test::More tests => 2400;
use Lingua::Stem::Snowball;
use File::Spec;

my @languages = qw( en da de es fi fr it nl no pt ru sv );
my $stemmer = Lingua::Stem::Snowball->new();

for my $iso (@languages) {

    # set language
    $stemmer->lang($iso);
    
    # test ISO-8859-1 / KOI8-R vocab
    my $default_enc_voc_path
        = File::Spec->catfile( 't', 'test_voc', "$iso.default_enc" );
    open( my $default_enc_voc_fh, '<', $default_enc_voc_path )
        or die "Couldn't open file '$default_enc_voc_path' for reading: $!";
    $stemmer->encoding( $iso eq 'ru' ? 'KOI8-R' : 'ISO-8859-1' );
    while (<$default_enc_voc_fh>) {
        chomp;
        my ( $before, $after ) = split;
        my $stems = [$before];
        $stemmer->stem_in_place($stems);
        is( $stems->[0], $after );
    }
    
    # test UTF-8 vocab
    my $utf8_voc_path = File::Spec->catfile( 't', 'test_voc', "$iso.utf8" );
    open( my $utf8_voc_fh, '<:utf8', $utf8_voc_path )
        or die "Couldn't open file '$utf8_voc_path' for reading: $!";
    $stemmer->encoding('UTF-8');
    while (<$utf8_voc_fh>) {
        chomp;
        my ( $before, $after ) = split;
        my $stems = [$before];
        $stemmer->stem_in_place($stems);
        is( $stems->[0], $after );
    }
}

