#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use UI::Dialog::Backend::XOSD;

my @opts = ( debug => 3,
             font => "lucidasans-bold-24",
             #	font => "-*-fixed-*-*-*-*-20-*-*-*-*-*-iso8859-*",
             delay => 2,
             colour => "green",
             pos => "middle",
             align => "center" );

my $d = new UI::Dialog::Backend::XOSD ( @opts );

$d->display_start();
$d->display_text("this is a test");
sleep(1);
$d->display_text("so is this");
sleep(1);
$d->display_gauge( 25, "even testing a gauge!" );
$d->display_stop();

$d->line( text => "this is a line test" );
$d->gauge( text => "gauging something", percent => "45" );
$d->gauge( text => "gauging something again", percent => "85" );
$d->file( file => $0, lines => 5, indent => 5, align => 'left' );

