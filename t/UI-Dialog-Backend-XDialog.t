# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More ( skip_all => "Skipped until better tests are written." );

# use Test::More;
# BEGIN { use_ok( 'UI::Dialog::Backend::XDialog' ); }
# require_ok( 'UI::Dialog::Backend::XDialog' );

#########################

# my $obj = UI::Dialog::Backend::XDialog->new();
# isa_ok( $obj, 'UI::Dialog::Backend::XDialog' );

# my @methods = qw( new state ra rs rv nautilus xosd beep clear
#                   yesno msgbox inputbox password textbox menu
#                   checklist radiolist fselect dselect
#                   _del_progress _del_gauge _mk_cmnd state combobox
#                   rangebox rangesbox2 rangesbox3 spinbox spinsbox2
#                   spinsbox3 buildlist treeview calendar timebox
#                   inputsbox2 inputsbox3 passwords2 passwords3
#                   msgbox infobox textbox editbox logbox tailbox
#                   progress_start progress_inc progress_dec
#                   progress_set progress_stop gauge_start gauge_inc
#                   gauge_dec gauge_set gauge_text gauge_stop );
# can_ok( 'UI::Dialog::Backend::XDialog', @methods );

# done_testing();
