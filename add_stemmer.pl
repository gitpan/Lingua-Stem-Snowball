#!/usr/bin/perl

use strict;
use Archive::Tar;

unlink 'stemmers_src/tests.txt';

unlink "stemmers_src/stem_*";
foreach my $file (qw(da de dk en es fi fr it no pt ru sv)) {
	add_stemmer("stemmers_src/$file.tgz", $file);
}

sub add_stemmer {
	my ($tgz, $lang) = @_;

	if (($tgz !~ /\.(tgz|tar\.gz)/) and (! -e $ARGV[1])) {
		die "You must give a valid .tgz filename.\n";
	}

	if (!$lang) {
		die "You must give the ISO language.\n";
	}
	
	my $tar = Archive::Tar->new();
	$tar->read($tgz, 1);
	
	my @files = $tar->get_files();
	my ($dir) = split m#/#, $files[0]->name;
	unless ($dir) {
		die "All files in archive must be in a directory!\n";
	}
	
	my $h = $tar->get_content("$dir/stem.h");
	unless ($h) {
		die "No stem.h file!\n";
	}
	$h =~ s/$dir\_/$lang\_/g;
	open(I, ">stemmers_src/stem_$lang.h");
	print I $h;
	close(I);
	
	my $c = $tar->get_content("$dir/stem.c");
	unless ($c) {
		die "No stem.c file!\n";
	}
	$c =~ s/$dir\_/$lang\_/g;
	open(I, ">stemmers_src/stem_$lang.c");
	print I $c;
	close(I);

	if (open(HEAD, 'stemmers_src/stem.h')) {
		my $head = join(' ', <HEAD>);
		close HEAD;
		unless (
			$head =~ /\b${lang}_create_env\b/ &&
			$head =~ /\b${lang}_close_env\b/ &&
			$head =~ /\b${lang}_stem\b/
		) {
			die "$lang is not a valid stemmer!\n";
		}
	}

	my $voc = $tar->get_content("$dir/voc.txt");
	my $output = $tar->get_content("$dir/output.txt");
	if ($voc and $output) {
		my @vocs = split /\n/, $voc;
		my @outputs = split /\n/, $output;

		# We take 10 random
		my $max = @vocs;
		my $tests;
		my $i = 0;
		while ($i < 100) {
			my $r = int(rand($max));
			$tests .= qq~$lang|$vocs[$r]|$outputs[$r]\n~;
			$i++;
		}

		open(F, ">>stemmers_src/tests.txt");
		print F $tests;
		close(F);
	}
}
