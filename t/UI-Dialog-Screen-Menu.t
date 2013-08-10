# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More ( skip_all => "Skipped until better tests are written." );

# use Test::More ( tests => 4 );
# BEGIN { use_ok( 'UI::Dialog::Screen::Menu' ); }
# require_ok( 'UI::Dialog::Screen::Menu' );

# #########################

# # Insert your test code below, the Test::More module is use()ed here so read
# # its man page ( perldoc Test::More ) for help writing this test script.

# my $obj = UI::Dialog::Screen::Menu->new();
# isa_ok( $obj, 'UI::Dialog::Screen::Menu' );

# my @methods = qw( new run loop is_looping break_loop
#                   add_menu_item get_menu_items del_menu_item set_menu_item
#                  );
# can_ok( 'UI::Dialog::Screen::Menu', @methods );
