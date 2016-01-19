# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More ( skip_all => "Skipped until better tests are written." );

#use Test::More ( tests => 15 );
use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::Whiptail' ); }
require_ok( 'UI::Dialog::Backend::Whiptail' );

# #########################

# # Insert your test code below, the Test::More module is use()ed here so read
# # its man page ( perldoc Test::More ) for help writing this test script.


#
# Note that we don't test fselect and dselect with Whiptail because
# those methods just wrap the menu and other functions. Whiptail does not
# have a dedicated fselect or dselect option.
#


my $obj = new UI::Dialog::Backend::Whiptail
  ( test_mode => 1 );
isa_ok( $obj, 'UI::Dialog::Backend::Whiptail' );

my $bin = $obj->get_bin();

my @methods = qw( new state ra rs rv nautilus xosd beep clear
                  yesno msgbox inputbox password textbox menu
                  checklist radiolist fselect dselect );
can_ok( 'UI::Dialog::Backend::Whiptail', @methods );

$obj->yesno( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
             width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --backtitle "BACKTITLE" --yesno "TEXT" "16" "64"'
  );

$obj->msgbox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
              width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --backtitle "BACKTITLE" --scrolltext --msgbox "TEXT" "16" "64"'
  );

$obj->infobox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
               width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --backtitle "BACKTITLE" --scrolltext --infobox "TEXT" "16" "64"'
  );

$obj->inputbox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                width => 64, height => 16, entry => "ENTRY" );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --backtitle "BACKTITLE" --inputbox "TEXT" "16" "64" "ENTRY"'
  );

$obj->password( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                width => 64, height => 16, entry => "ENTRY" );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --backtitle "BACKTITLE" --passwordbox "TEXT" "16" "64" "ENTRY"'
  );

$obj->textbox( title=>"TITLE", backtitle => "BACKTITLE", path => "$0",
               width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --backtitle "BACKTITLE" --scrolltext --textbox "'.$0.'" "16" "64"'
  );

$obj->menu( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
            width => 64, height => 16,
            list => [ "tag0", "item0", "tag1", "item1" ] );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --backtitle "BACKTITLE" --separate-output --menu "TEXT" "16" "64" "10"  "tag0" "item0" "tag1" "item1"'
  );

$obj->checklist( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                 width => 64, height => 16,
                 list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --backtitle "BACKTITLE" --separate-output --checklist "TEXT" "16" "64" "10"  "tag0" "item0" "off" "tag1" "item1" "on"'
  );

$obj->radiolist( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                 width => 64, height => 16,
                 list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --backtitle "BACKTITLE" --separate-output --radiolist "TEXT" "16" "64" "10"  "tag0" "item0" "off" "tag1" "item1" "on"'
  );


#
# Now test the trust-input feature for the Whiptail backend.
#

$obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
              backtitle => 'BACKTITLE: `head -1 '.$0.'`',
              text => 'TEXT: $(head -1 '.$0.')',
              width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE: \'head -1 '.$0.'\'" --backtitle "BACKTITLE: \'head -1 '.$0.'\'" --scrolltext --msgbox "TEXT: (head -1 '.$0.')" "16" "64"'
  );

$obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
              backtitle => 'BACKTITLE: `head -1 '.$0.'`',
              text => 'TEXT: $(head -1 '.$0.')',
              'trust-input' => 1,
              width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE: `head -1 '.$0.'`" --backtitle "BACKTITLE: `head -1 '.$0.'`" --scrolltext --msgbox "TEXT: $(head -1 '.$0.')" "16" "64"'
  );

done_testing();
