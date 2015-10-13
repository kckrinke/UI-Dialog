# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More ( skip_all => "Skipped until better tests are written." );

#use Test::More ( tests => 15 );
use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::Zenity' ); }
require_ok( 'UI::Dialog::Backend::Zenity' );

# #########################

my $obj = new UI::Dialog::Backend::Zenity
  ( test_mode => 1 );
isa_ok( $obj, 'UI::Dialog::Backend::Zenity' );

my $bin = $obj->get_bin();

my @methods = qw( new state ra rs rv nautilus xosd beep clear
                  yesno msgbox inputbox password textbox menu
                  checklist radiolist fselect dselect );
can_ok( 'UI::Dialog::Backend::Zenity', @methods );

$obj->yesno( title=>"TITLE", text => "TEXT",
             width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --width "64" --height "16" --question --text "TEXT"'
  );

$obj->msgbox( title=>"TITLE", text => "TEXT",
              width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --width "64" --height "16" --info --text "TEXT"'
  );

$obj->infobox( title=>"TITLE", text => "TEXT",
               width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --width "64" --height "16" --info --text "TEXT"'
  );

$obj->inputbox( title=>"TITLE", text => "TEXT",
                width => 64, height => 16, entry => "ENTRY" );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --width "64" --height "16" --entry --entry-text "ENTRY" --text "TEXT"'
  );

$obj->password( title=>"TITLE", text => "TEXT",
                width => 64, height => 16, entry => "ENTRY" );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --width "64" --height "16" --entry --hide-text --entry-text "ENTRY" --text "TEXT"'
  );

$obj->textbox( title=>"TITLE", path => "$0",
               width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --width "64" --height "16" --text-info --filename "t/UI-Dialog-Backend-Zenity.t"'
  );

$obj->menu( title=>"TITLE", text => "TEXT",
            width => 64, height => 16,
            list => [ "tag0", "item0", "tag1", "item1" ] );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --width "64" --height "16" --list --separator $'."'\\n'".' --column " " --column " " "tag0" "item0" "tag1" "item1"'
  );

$obj->checklist( title=>"TITLE", text => "TEXT",
                 width => 64, height => 16,
                 list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --width "64" --height "16" --list --checklist --separator $'."'\\n'".' --column " " --column " " --column " " "FALSE" "tag0" "item0" "TRUE" "tag1" "item1"'
  );

$obj->radiolist( title=>"TITLE", text => "TEXT",
                 width => 64, height => 16,
                 list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE" --width "64" --height "16" --list --radiolist --separator $'."'\\n'".' --column " " --column " " --column " " "FALSE" "tag0" "item0" "TRUE" "tag1" "item1"'
  );


#
# Now test the trust-input feature for the Zenity backend.
#

$obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
              backtitle => 'BACKTITLE: `head -1 '.$0.'`',
              text => 'TEXT: $(head -1 '.$0.')',
              width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE: \'head -1 '.$0.'\'" --width "64" --height "16" --info --text "TEXT: (head -1 '.$0.')"'
  );

$obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
              backtitle => 'BACKTITLE: `head -1 '.$0.'`',
              text => 'TEXT: $(head -1 '.$0.')',
              'trust-input' => 1,
              width => 64, height => 16 );
is( $obj->get_unit_test_result(),
    $bin.' --title "TITLE: `head -1 '.$0.'`" --width "64" --height "16" --info --text "TEXT: $(head -1 '.$0.')"'
  );

done_testing();
