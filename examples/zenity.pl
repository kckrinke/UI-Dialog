#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

use UI::Dialog::Backend::Zenity;


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
    printerr("CB_PRE > ".$func." (This is executed before any widget does anything.)\n");
}
sub CB_POST {
    my $args = shift();
    my $func = $args->{'caller'};
    my $state = shift()||'NULL';
    printerr("CB_POST > ".$func." > ".$state." (This is executed after any widget has completed it's run.)\n");
}

my $d = new UI::Dialog::Backend::Zenity ( title => "UI::Dialog::Backend::Zenity Demo",
										  debug => 0, height => 20, width => 65,
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
			'a lightbulb icon to the left of this text message, ' .
			'and the title of this message box should be "$d->msgbox()".' );
$d->warning( title => '$d->warning()',
			 text =>  'This is the warning widget. ' .
			 'There should be "OK" and "CANCEL" buttons below this text message, ' .
			 'a warning icon to the left of this text message, ' .
			 'and the title of this message box should be "$d->warning()".' );
$d->error( title => '$d->error()',
		   text =>  'This is the error widget. ' .
		   'There should be a single "OK" button below this text message, ' .
		   'an error icon to the left of this text message ' .
		   'and the title of this message box should be "$d->error()".' );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if ($d->yesno( title => '$d->yesno()',
			   text => 'This is a question widget. '.
			   'There should be "OK" and "CANCEL" buttons below this text message. '.
			   'a question mark icon to the left of this text message ' .
			   'and the title of this message box should be "$d->yesno()".' )) {
    printerr("The user has answered YES to the yesno widget.\n");
} else {
    printerr("The user has answered NO to the yesno widget.\n");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$d->gauge_start( title => '$d->gauge_start()',
				 text => 'This is a progress indicator.' );
foreach my $i (20,40,60,80,100) {
    last unless $d->gauge_set($i);
    sleep(1);
}
$d->gauge_stop();
$d->gauge_start( title => '$d->gauge_start() #pulsate', pulsate => 1,
				 text => 'This is a pulsating progress indicator.' );
foreach my $i (20,40,60,80,100) {
    last unless $d->gauge_set($i);
    sleep(1);
}
$d->gauge_stop();


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
my $editbox = $d->editbox( title => '$d->editbox()', path => $0 );
if ($d->state() eq "OK") {
    print "Your edited text:\n\n[BEGIN TEXT]\n".($editbox||'NULL')."\n[END TEXT]\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $menuSelect = $d->menu( title => '$d->menu()', text=>'select:',
						   list => [ 'Test', 'testing',
									 'Zen', 'zenity' ] );
if ($d->state() eq "OK") {
    print "You selected: '".($menuSelect||'NULL')."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my @checkSelect = $d->checklist( title => '$d->checklist()',
								 text => 'select:',
								 list => [ 'Test', [ 'testing', 1 ],
										   'Zen', [ 'zenity', '0' ] ] );
if ($d->state() eq "OK") {
    print "You selected: '".(join("' '",@checkSelect))."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $radioSelect = $d->radiolist( title => '$d->radiolist()',
								 text => 'select:',
								 list =>[ 'test', [ 'testing', 0 ],
										  'Zen', [ 'zenity', 1 ] ]);
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

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my ($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime(time());
my $dateSelect = $d->calendar( title => '$d->calendar()', height => 14,
							   day => $mday, month => $month, year => ($year + 1900) );
my @date = $d->ra();
if ($d->state() eq "OK") {
    print "You selected: '".($dateSelect||'NULL')."' or rather: ".$date[0]." day, ".$date[1]." month, ".$date[2]." year.\n";
}

exit();
