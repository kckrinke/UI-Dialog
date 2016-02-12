use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::XOSD' ); }
require_ok( 'UI::Dialog::Backend::XOSD' );

# #########################

my $obj = UI::Dialog::Backend::XOSD->new();
isa_ok( $obj, 'UI::Dialog::Backend::XOSD' );

my @methods =
  qw( new line file gauge
      display_start display_stop
      display_text display_gauge
   );
can_ok( 'UI::Dialog::Backend::XOSD', @methods );
done_testing();
