#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

use UI::Dialog::Backend::ASCII;

#sub printerr { 1; }
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

my $d = new UI::Dialog::Backend::ASCII ( title => "UI::Dialog::Backend::ASCII Demo",
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
$d->infobox( title => '$d->infobox', timeout => 6000,
			 text => 'This is the infobox widget. '.
			 'There should be no buttons below this text message, '.
			 'the title of this message box should be "$d->infobox()", ' .
			 'and this should disappear after 6 seconds.' );
$d->msgbox( title => '$d->msgbox()',
			text =>  'This is the msgbox widget. ' .
			'There should be a prompt below this text message informing you to ' .
			'[ Press Enter To Continue ], ' .
			'and the title of this message box should be "$d->msgbox()".' );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if ($d->yesno( title => '$d->yesno()',
			   text => 'This is a question widget. '.
			   'There should be a prompt below this text message '.
			   'indicating (Yes|no) (the one with the capital letter is the default for ' .
			   'when you enter nothing), ' .
			   'and the title of this message box should be "$d->yesno()".' )) {
    printerr("The user has answered YES to the yesno widget.\n");
} else {
    printerr("The user has answered NO to the yesno widget.\n");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
foreach my $i (20,40,60,80,100) {
    last unless $d->draw_gauge( text => "gauge message. Current: ".$i, percent => $i );
    sleep(1);
}
$d->end_gauge();
# foreach my $i (100,1000,2000,6000,9000,12345) {
#   last unless $d->draw_gauge( bar => "-", mark => "|", length => 74,
#                               current => $i, total => 12345 );
#   sleep(1);
# }
# $d->end_gauge();

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print STDOUT "spinner... ";
for (20,40,60,80,100) { print $d->spinner(); sleep(1); }
print STDOUT "\bdone.\n";

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
									 'ASCII', 'ascii' ] );
if ($d->state() eq "OK") {
    print "You selected: '".($menuSelect||'NULL')."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my @checkSelect = $d->checklist( title => '$d->checklist()',
								 text => 'select:',
								 list => [ 'Test', [ 'testing', 1 ],
										   'ASCII', [ 'ascii', '0' ] ] );
if ($d->state() eq "OK") {
    print "You selected: '".(join("' '",@checkSelect))."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $radioSelect = $d->radiolist( title => '$d->radiolist()',
								 text => 'select:',
								 list =>[ 'test', [ 'testing', 0 ],
										  'ASCII', [ 'ascii', 1 ] ]);
if ($d->state() eq "OK") {
    print "You selected: '".$radioSelect."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $dirname = $d->dselect( title => '$d->dselect()',
						   path => "/" );
if ($d->state() eq "OK") {
    print "You selected: '".$dirname."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $filename = $d->fselect( title => '$d->fselect()',
							path => $dirname );
if ($d->state() eq "OK") {
    print "You selected: '".$filename."'\n";
}


exit();


