#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use FileHandle;
use UI::Dialog::Backend::XDialog;

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

my $d = new UI::Dialog::Backend::XDialog ( title => "UI::Dialog::Backend::Zenity Demo",
										   debug => 1, height => 20, width => 65,
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

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if ($d->yesno( title => '$d->yesno()',
			   text => 'This is a question widget. '.
			   'There should be "OK" and "CANCEL" buttons below this text message. '.
			   'and the title of this message box should be "$d->yesno()".' )) {
    printerr("The user has answered YES to the yesno widget.\n");
} else {
    printerr("The user has answered NO to the yesno widget.\n");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$d->infobox( timeout => 6000, title => '$d->infobox()',
			 text => 'This is an infobox widget. '.
		     'There should be an "OK" button below this message, '.
		     'and the title of this info box should be "$d->infobox()". '.
		     'This will self destruct in 6 seconds.');

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$d->gauge_start( title => '$d->gauge_start()',
				 text => 'This is a gauge indicator.' );
foreach my $i (20,40,60,80,100) {
    last unless $d->gauge_set($i);
    sleep(1);
}
$d->gauge_stop();
$d->progress_start( title => '$d->progress_start()',
					text => 'This is a progress indicator.' );
foreach my $i (20,40,60,80,100) {
    last unless $d->progress_set($i);
    sleep(1);
}
$d->progress_stop();
# duality test
$d->gauge_start( text => 'gauge...', begin => [ 10, 10 ] );
$d->progress_start( text => 'progress...' );
foreach my $i (20,40,60,80,100) {
    last unless $d->gauge_set($i);
    sleep(1);
    last unless $d->progress_set($i);
    sleep(1);
}
$d->gauge_stop();
$d->progress_stop();


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $inputbox = $d->inputbox( title => '$d->inputbox()',
							 text => 'Please enter some text below:',
                             entry => 'preset text entry' );
if ($d->state() eq "OK") {
    print "You input: ".($inputbox||'NULL')."\n";
}
#: inputsbox2
my @inputsbox2 = $d->inputsbox2( title => '$d->inputsbox2()',
								 text => 'Please enter some text below:',
								 label1 => 'label1', label2 => 'label2',
								 input1 => 'field1', input2 => 'field2');
if ($d->state() eq "OK") {
    print "You entered: '".(join("' '",@inputsbox2)||'NULL')."'\n";
}

#: inputsbox3
my @inputsbox3 = $d->inputsbox3( title => '$d->inputsbox3()',
								 text => 'Please enter some text below:',
								 label1 => 'label1', label2 => 'label2', label3 => 'label3',
								 input1 => 'field1', input2 => 'field2', input3 => 'field3' );
if ($d->state() eq "OK") {
    print "You entered: '".(join("' '",@inputsbox3)||'NULL')."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $password = $d->password( title => '$d->password()',
							 text => 'Please input text below: (text should be hidden)' );
if ($d->state() eq "OK") {
    print "You input: ".($password||'NULL')."\n";
}
#: passwords2
my @passwords2 = $d->passwords2(text=>'Please enter some text below: (text should be hidden)',
								label1=>'label1',label2=>'label2');
if ($d->state() eq "OK") {
    print "You entered: '".(join("' '",@passwords2)||'NULL')."'\n";
}
#: passwords3
my @passwords3 = $d->passwords3(text=>'Please enter some text below: (text should be hidden)',
								label1=>'label1',label2=>'label2',label3=>'label3');
if ($d->state() eq "OK") {
    print "You entered: '".(join("' '",@passwords3)||'NULL')."'\n";
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
									 'Xd', 'XDialog' ] );
if ($d->state() eq "OK") {
    print "You selected: '".($menuSelect||'NULL')."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my @checkSelect = $d->checklist( title => '$d->checklist()',
								 text => 'select:',
								 list => [ 'Test', [ 'testing', 1 ],
										   'Xd', [ 'XDialog', '0' ] ] );
if ($d->state() eq "OK") {
    print "You selected: '".(join("' '",@checkSelect))."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $radioSelect = $d->radiolist( title => '$d->radiolist()',
								 text => 'select:',
								 list =>[ 'test', [ 'testing', 0 ],
										  'Xd', [ 'XDialog', 1 ] ]);
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
my $comboSelect = $d->combobox( editable => 1, title => '$d->combobox()',
								text => 'select:', list => [ 'test', 'Xdialog' ] );
if ($d->state() eq "OK") {
    print "You selected: '".($comboSelect||'NULL')."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $rangeSelect = $d->rangebox( title => '$d->rangebox()',
								text => 'set:', min => 10, max => 100, def => 54 );
if ($d->state() eq "OK") {
    print "You selected: '".($rangeSelect||'NULL')."'\n";
}

my @rangeSelect2 = $d->rangesbox2( text => 'set:', title => '$d->rangesbox2()',
								   label1 => 'one', min1 => 10, max1 => 100, def1 => 54,
								   label2 => 'two', min2 => 1, max2 => 10, def2 => 5 );
if ($d->state() eq "OK") {
    print "You selected: '".(join("' '",@rangeSelect2))."'\n";
}

my @rangeSelect3 = $d->rangesbox3( text => 'set:', title => '$d->rangesbox3()',
								   label1 => 'one', min1 => 10, max1 => 100, def1 => 54,
								   label2 => 'two', min2 => 1, max2 => 10, def2 => 5,
								   label2 => 'three', min3 => 100, max3 => 1000, def3 => 500 );
if ($d->state() eq "OK") {
    print "You selected: '".(join("' '",@rangeSelect3))."'\n";
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $spinSelect = $d->spinbox( title => '$d->spinbox()', text => 'set:',
							  min => 10, max => 100, def => 54, label1 => 'label' );
if ($d->state() eq "OK") {
    print "You selected: '".($spinSelect||'null')."'\n";
}

my @spinsSelect2 = $d->spinsbox2( text => 'set:', title => '$d->spinsbox2()',
								  label1 => 'one', min1 => 10, max1 => 100, def1 => 54,
								  label2 => 'two', min2 => 1, max2 => 10, def2 => 5);
if ($d->state() eq "OK") {
    print "You selected: '".(join("' '",@spinsSelect2))."'\n";
}

my @spinsSelect3 = $d->spinsbox3( text => 'set:', title => '$d->spinsbox3()',
								  label1 => 'one', min1 => 10, max1 => 100, def1 => 54,
								  label2 => 'two', min2 => 1, max2 => 10, def2 => 5,
								  label2 => 'three', min3 => 100, max3=> 1000, def3 => 500 );
if ($d->state() eq "OK") {
    print "You selected: '".(join("' '",@spinsSelect3))."'\n";
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$d->tailbox( title => '$d->tailbox()', filename => $0 );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$d->logbox( title => '$d->logbox()', filename => $0 );


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my @buildSelect = $d->buildlist(text=>'select:',
								list=>['test',['testing',1],
									   'Xd',['Xdialog',0],
									   'more',['much more',1]]);
if ($d->state() eq "OK") {
    print "You selected: '".(join("' '",@buildSelect))."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $treeSelect = $d->treeview(text=>'select:',
							  list=>['r1',['root',1,1],
									 'b1',['branch1',1,2],
									 'b2',['branch2',1,2],
									 'r2',['another root',1,1],
									 'b3',['branch3',1,2],
									 's1',['subbranch1',1,3]
									]);
if ($d->state() eq "OK") {
    print "You selected: '".($treeSelect||'NULL')."'\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my ($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime(time());
my $timeSelect = $d->timebox( text => 'select:', height => 11,
							  second => $sec, minute => $min, hour => $hour );
my @time = $d->ra();
if ($d->state() eq "OK") {
    print "You selected: '".($timeSelect||'NULL')."' or rather: ".$time[0]." hour, ".$time[1]." minute, ".$time[2]." second.\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $dateSelect = $d->calendar( title => '$d->calendar()', height => 14,
							   day => $mday, month => $month, year => ($year + 1900) );
my @date = $d->ra();
if ($d->state() eq "OK") {
    print "You selected: '".($dateSelect||'NULL')."' or rather: ".$date[0]." day, ".$date[1]." month, ".$date[2]." year.\n";
}


exit();














