#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

use UI::Dialog::GNOME;
my $d = new UI::Dialog::GNOME;

my @paths = $d->nautilus->paths();
my @uris = $d->nautilus->uris();
my $path = $d->nautilus->path();
my $uri = $d->nautilus->uri();
my @geo = $d->nautilus->geometry();

$d->msgbox(text=>[
				  'paths: '.join(" ",@paths),
				  'uris: '.join(" ",@uris),
				  'path: '.$path,
				  'uri: '.$uri,
				  'geo: '.join(" ",@geo)
				 ]);

