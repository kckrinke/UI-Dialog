# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::CDialog' ); }
require_ok( 'UI::Dialog::Backend::CDialog' );

#########################

eval { new UI::Dialog::Backend::CDialog(test_mode=>1); };
if ( $@ ) {
  if ($@ =~ m!binary could not be found!) {
    diag("Tests skipped, backend binary not found.");
  }
  else {
    diag("An unknown error occurred while trying to use backend: ".$@);
  }
  done_testing();
}
else {

  my $obj = new UI::Dialog::Backend::CDialog
    ( test_mode => 1 );
  isa_ok( $obj, 'UI::Dialog::Backend::CDialog' );

  my $bin = $obj->get_bin();

  my @methods = qw( new state ra rs rv nautilus xosd beep clear
                    yesno msgbox inputbox password textbox menu
                    checklist radiolist fselect dselect );
  can_ok( 'UI::Dialog::Backend::CDialog', @methods );

  $obj->yesno( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
               width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE" --backtitle "BACKTITLE" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --yesno "TEXT" "16" "64"'
    );

  $obj->msgbox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE" --backtitle "BACKTITLE" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --msgbox "TEXT" "16" "64"'
    );

  $obj->infobox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE" --backtitle "BACKTITLE" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --infobox "TEXT" "16" "64"'
    );

  $obj->inputbox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                  width => 64, height => 16, entry => "ENTRY" );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE" --backtitle "BACKTITLE" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --inputbox "TEXT" "16" "64" "ENTRY"'
    );

  $obj->password( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                  width => 64, height => 16, entry => "ENTRY" );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE" --backtitle "BACKTITLE" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --passwordbox "TEXT" "16" "64" "ENTRY"'
    );

  $obj->textbox( title=>"TITLE", backtitle => "BACKTITLE", path => "$0",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE" --backtitle "BACKTITLE" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --scrolltext --textbox "'.$0.'" "16" "64"'
    );

  $obj->menu( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
              width => 64, height => 16,
              list => [ "tag0", "item0", "tag1", "item1" ] );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE" --backtitle "BACKTITLE" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --separate-output --menu "TEXT" "16" "64" "5"  "tag0" "item0" "tag1" "item1"'
    );

  $obj->checklist( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                   width => 64, height => 16,
                   list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE" --backtitle "BACKTITLE" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --separate-output --checklist "TEXT" "16" "64" "5"  "tag0" "item0" "off" "tag1" "item1" "on" "tag0" "item0" "off" "tag1" "item1" "on"'
    );

  $obj->radiolist( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                   width => 64, height => 16,
                   list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE" --backtitle "BACKTITLE" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --radiolist "TEXT" "16" "64" "5"  "tag0" "item0" "off" "tag1" "item1" "on" "tag0" "item0" "off" "tag1" "item1" "on"'
    );


  #
  # Now test the trust-input feature for the CDialog backend.
  #

  $obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
                backtitle => 'BACKTITLE: `head -1 '.$0.'`',
                text => 'TEXT: $(head -1 '.$0.')',
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE: \'head -1 '.$0.'\'" --backtitle "BACKTITLE: \'head -1 '.$0.'\'" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --msgbox "TEXT: (head -1 '.$0.')" "16" "64"'
    );

  $obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
                backtitle => 'BACKTITLE: `head -1 '.$0.'`',
                text => 'TEXT: $(head -1 '.$0.')',
                'trust-input' => 1,
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE: `head -1 '.$0.'`" --backtitle "BACKTITLE: `head -1 '.$0.'`" --defaultno --extra-button --help-button --no-cancel --no-collapse --no-shadow --shadow --tab-correct --max-input "" --tab-len "" --msgbox "TEXT: $(head -1 '.$0.')" "16" "64"'
    );

  done_testing();
}
