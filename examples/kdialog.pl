#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

use UI::Dialog::Backend::KDialog;

sub printerr { print STDERR 'UI::Dialog : '.join( " ", @_ ); }
sub CB_CANCEL {
  my $args = shift();
  my $func = $args->{'caller'};
  printerr("CB_CANCEL > ".$func." (This is executed when the user presses the CANCEL button.)\n");
}
sub CB_OK {
  my $args = shift();
  my $func = $args->{'caller'};
  printerr("CB_OK > ".$func." (This is executed when the user presses the OK button.)\n");
}
sub CB_ESC {
  my $args = shift();
  my $func = $args->{'caller'};
  printerr("CB_ESC > ".$func." (This is executed when the user presses the ESC button.)\n");
}
sub CB_PRE {
  my $args = shift();
  my $func = $args->{'caller'};
  sleep(1); # we wait for a second so that the user can digest STDERR before the next widget...
  printerr("CB_PRE > ".$func." (This is executed before any widget does anything.)\n");
}
sub CB_POST {
  my $args = shift();
  my $func = $args->{'caller'};
  my $state = shift()||'NULL';
  printerr("CB_POST > ".$func." > ".$state." (This is executed after any widget has completed it's run.)\n");
}

my $d = new UI::Dialog::Backend::KDialog
  ( title => "UI::Dialog::Backend::KDialog Demo",
    debug => 0, height => 20, width => 65, listheight => 10,
    callbacks => { CANCEL => \&CB_CANCEL,
                   ESC => \&CB_ESC,
                   OK => \&CB_OK,
                   PRE => \&CB_PRE,
                   POST => \&CB_POST } );

sub CALLBACK_TEST {
  $d->msgbox( title => '$d->msgbox()',
              text =>  'This is a test of the callback functionality. '.
              'On the console STDERR output you should see "CB_PRE > main::CALLBACK_TEST". '.
              'This is because this msgbox() widget has been called from a function named CALLBACK_TEST.' );
}
CALLBACK_TEST();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$d->msgbox( title => '$d->msgbox()',
            text =>  'This is the msgbox widget. ' .
            'There should be a single "OK" button below this text message, ' .
            'and the title of this message box should be "$d->msgbox()".' );
$d->sorry( title => '$d->sorry()',
           text =>  'This is the sorry widget. ' .
           'There should be a single "OK" button below this text message, ' .
           'and the title of this message box should be "$d->sorry()".' );
$d->error( title => '$d->error()',
           text =>  'This is the error widget. ' .
           'There should be a single "OK" button below this text message, ' .
           'and the title of this message box should be "$d->error()".' );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if ($d->yesno( title => '$d->yesno()',
               text => 'This is a question widget. '.
               'There should be "YES" and "NO" buttons below this text message. '.
               'and the title of this message box should be "$d->yesno()".' )) {
  printerr("The user has answered YES to the yesno widget.\n");
}
else {
  printerr("The user has answered NO to the yesno widget.\n");
}
if ($d->yesnocancel( title => '$d->yesnocancel()',
                     text => 'This is a question widget. '.
                     'There should be "YES", "NO" and "CANCEL" buttons below this text message. '.
                     'and the title of this message box should be "$d->yesnocancel()".' )) {
  printerr("The user has answered YES to the yesnocancel widget.\n");
}
else {
  printerr("The user has answered NO to the yesnocancel widget.\n");
}
if ($d->warningyesno( title => '$d->warningyesno()',
                      text => 'This is a question widget. '.
                      'There should be "YES" and "NO" buttons below this text message. '.
                      'and the title of this message box should be "$d->warningyesno()".' )) {
  printerr("The user has answered YES to the warningyesno widget.\n");
}
else {
  printerr("The user has answered NO to the warningyesno widget.\n");
}
if ($d->warningyesnocancel( title => '$d->warningyesnocancel()',
                            text => 'This is a question widget. '.
                            'There should be "YES", "NO" and "CANCEL" buttons below this text message. '.
                            'and the title of this message box should be "$d->warningyesnocancel()".' )) {
  printerr("The user has answered YES to the warningyesnocancel widget.\n");
}
else {
  printerr("The user has answered NO to the warningyesnocancel widget.\n");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $inputbox = $d->inputbox( title => '$d->inputbox()',
                             text => 'Please enter some text below:',
                             entry => 'preset text entry' );
if ($d->state() eq "OK") {
  print "You input: ".($inputbox||'NULL')."\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $password = $d->password( title => '$d->password()',
                             text => 'Please input text below: (text should be hidden)' );
if ($d->state() eq "OK") {
  print "You input: ".($password||'NULL')."\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$d->textbox( title => '$d->textbox()', path => $0 );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $menuSelect = $d->menu( title => '$d->menu()', text=>'select:',
                           list => [ 'Test', 'testing',
                                     'Kd', 'kdialog' ] );
if ($d->state() eq "OK") {
  print "You selected: '".($menuSelect||'NULL')."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my @checkSelect = $d->checklist( title => '$d->checklist()',
                                 text => 'select:',
                                 list => [ 'Test', [ 'testing', 1 ],
                                           'Kd', [ 'kdialog', '0' ] ] );
if ($d->state() eq "OK") {
  print "You selected: '".(join("' '",@checkSelect))."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $radioSelect = $d->radiolist( title => '$d->radiolist()',
                                 text => 'select:',
                                 list =>[ 'test', [ 'testing', 0 ],
                                          'Kd', [ 'kdialog', 1 ] ]);
if ($d->state() eq "OK") {
  print "You selected: '".$radioSelect."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $dirname = $d->getexistingdirectory( title => '$d->getexistingdirectory()',
                                        path => "/" );
if ($d->state() eq "OK") {
  print "You selected: '".$dirname."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $openfilename = $d->getopenfilename( title => '$d->getopenfilename()',
                                        path => $dirname );
if ($d->state() eq "OK") {
  print "You selected: '".$openfilename."'\n";
}
my $savefilename = $d->getsavefilename( title => '$d->getopenfilename()',
                                        path => $dirname );
if ($d->state() eq "OK") {
  print "You selected: '".$savefilename."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $openurl = $d->getopenurl( title => '$d->getopenurl()',
                              path => $dirname );
if ($d->state() eq "OK") {
  print "You selected: '".$openurl."'\n";
}
my $saveurl = $d->getsaveurl( title => '$d->getopenurl()',
                              path => $dirname );
if ($d->state() eq "OK") {
  print "You selected: '".$saveurl."'\n";
}


exit();



