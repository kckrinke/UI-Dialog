# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More ( skip_all => "Skipped until better tests are written." );

# use Test::More ( tests => 4 );
# BEGIN { use_ok( 'UI::Dialog::Backend::Zenity' ); }
# require_ok( 'UI::Dialog::Backend::Zenity' );

# #########################

# # Insert your test code below, the Test::More module is use()ed here so read
# # its man page ( perldoc Test::More ) for help writing this test script.

# my $obj = UI::Dialog::Backend::Zenity->new();
# isa_ok( $obj, 'UI::Dialog::Backend::Zenity' );

# my @methods = qw( new state ra rs rv nautilus xosd beep clear
#                   yesno msgbox inputbox password textbox menu
#                   checklist radiolist fselect dselect
#                   _del_gauge _mk_cmnd _is_version
#                   command_state command_string command_array
#                   question entry info error warning text_info
#                   editbox list calendar gauge_start gauge_inc
#                   gauge_dec gauge_set gauge_text gauge_stop
# 				);
# can_ok( 'UI::Dialog::Backend::Zenity', @methods );
