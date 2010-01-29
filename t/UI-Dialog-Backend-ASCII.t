# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More ( tests => 4 );
BEGIN { use_ok( 'UI::Dialog::Backend::ASCII' ); }
require_ok( 'UI::Dialog::Backend::ASCII' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $obj = UI::Dialog::Backend::ASCII->new();
isa_ok( $obj, 'UI::Dialog::Backend::ASCII' );

my @methods = qw( new state ra rs rv beep clear
                  yesno msgbox inputbox password textbox menu
                  checklist radiolist fselect dselect
                  spinner draw_gauge end_gauge );
can_ok( 'UI::Dialog::Backend::ASCII', @methods );
