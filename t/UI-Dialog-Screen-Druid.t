use Test::More;
BEGIN { use_ok( 'UI::Dialog::Screen::Druid' ); }
require_ok( 'UI::Dialog::Screen::Druid' );

# #########################

my $obj = UI::Dialog::Screen::Druid->new();
isa_ok( $obj, 'UI::Dialog::Screen::Druid' );

my @methods =
  qw( perform new
      add_input_step add_password_step
      add_menu_step add_yesno_step
   );
can_ok( 'UI::Dialog::Screen::Druid', @methods );
done_testing();
