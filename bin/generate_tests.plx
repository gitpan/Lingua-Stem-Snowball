#!/usr/bin/perl
use strict;
use warnings;

# generate_tests.plx 
# 
# Grab a sampling of vocab diffs from Snowball project and generate test pairs
# in both the default encoding and UTF-8.

use Encode;
use Getopt::Long qw( GetOptions );
use File::Spec::Functions qw( catfile catdir );

# --snowdir must be the "snowball_all" directory
my $snowdir;
GetOptions( 'snowdir=s' => \$snowdir );
die "Usage: ./bin/generate_tests.plx --snowdir=SNOWDIR"
    unless defined $snowdir;

my %languages = (
    en => 'english',
    da => 'danish',
    de => 'german',
    es => 'spanish',
    fi => 'finnish',
    fr => 'french',
    it => 'italian',
    nl => 'dutch',
    no => 'norwegian',
    pt => 'portuguese',
    ru => 'russian',
    sv => 'swedish',
);

# create t/testvoc if it doesn't exist already
my $test_voc_dir = catdir( 't', 'test_voc' );
if ( !-d $test_voc_dir ) {
    mkdir $test_voc_dir or die $!;
}

while ( my ( $iso, $language ) = each %languages ) {
    # suck in all the lines of the relevant diffs.txt.
    my $in_filepath
        = catfile( $snowdir, 'algorithms', $language, 'diffs.txt' );
    open( my $in_fh, '<', $in_filepath ) or die $!;
    my @diffs = <$in_fh>;

    # these files are in the default encoding, so we'll have to decode UTF-8
    my $source_enc = $iso eq 'ru' ? 'koi8-r' : 'iso-8859-1';
    open( my $utf8_fh, '>:utf8', catfile( $test_voc_dir, "$iso.utf8" ) )
        or die $!;
    open( my $default_fh, ">", catfile( $test_voc_dir, "$iso.default_enc" ) )
        or die $!;

    # grab 100 random pairs
    for ( 1 .. 100 ) {
        my $pair = $diffs[ rand @diffs ];
        print $default_fh $pair or die $!;
        $pair = decode( $source_enc, $pair );
        print $utf8_fh $pair or die $!;
    }
}

