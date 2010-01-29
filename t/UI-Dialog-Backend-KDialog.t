# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More ( skip_all => "Skipped until better tests are written." );

# use Test::More ( tests => 4 );
# BEGIN { use_ok( 'UI::Dialog::Backend::KDialog' ); }
# require_ok( 'UI::Dialog::Backend::KDialog' );

# #########################

# # Insert your test code below, the Test::More module is use()ed here so read
# # its man page ( perldoc Test::More ) for help writing this test script.

# my $obj = UI::Dialog::Backend::KDialog->new();
# isa_ok( $obj, 'UI::Dialog::Backend::KDialog' );

# my @methods = qw( new state ra rs rv nautilus xosd beep clear
#                   msgbox inputbox password textbox menu checklist radiolist
#                   yesno yesnocancel warningyesno warningyesnocancel
#                   fselect getopenfilename getsavefilename getopenurl getsaveurl
#                   dselect getexistingdirectory );
# can_ok( 'UI::Dialog::Backend::KDialog', @methods );
