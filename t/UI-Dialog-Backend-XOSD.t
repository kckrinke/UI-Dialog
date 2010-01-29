# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More ( skip_all => "Skipped until better tests are written." );

# use Test::More ( tests => 4 );
# BEGIN { use_ok( 'UI::Dialog::Backend::XOSD' ); }
# require_ok( 'UI::Dialog::Backend::XOSD' );

# #########################

# # Insert your test code below, the Test::More module is use()ed here so read
# # its man page ( perldoc Test::More ) for help writing this test script.

# my $obj = UI::Dialog::Backend::XOSD->new();
# isa_ok( $obj, 'UI::Dialog::Backend::XOSD' );

# my @methods = qw( new _del_display _gen_opt_str line file gauge
#                   display_start display_text display_gauge
#                   display_stop );
# can_ok( 'UI::Dialog::Backend::XOSD', @methods );
