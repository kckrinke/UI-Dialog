use Test::More;
BEGIN { use_ok( 'UI::Dialog::Screen::Menu' ); }
require_ok( 'UI::Dialog::Screen::Menu' );

# #########################

my $obj = UI::Dialog::Screen::Menu->new();
isa_ok( $obj, 'UI::Dialog::Screen::Menu' );

my @methods =
  qw( new run
      break_loop is_looping
      add_menu_item get_menu_items
      del_menu_item set_menu_item
   );
can_ok( 'UI::Dialog::Screen::Menu', @methods );
done_testing();
