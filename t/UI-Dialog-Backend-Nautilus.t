use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::Nautilus' ); }
require_ok( 'UI::Dialog::Backend::Nautilus' );

# #########################

my $obj = UI::Dialog::Backend::Nautilus->new();
isa_ok( $obj, 'UI::Dialog::Backend::Nautilus' );

my @methods =
  qw( new
      uri_unescape
      paths uris
      path uris
      geometry
   );
can_ok( 'UI::Dialog::Backend::Nautilus', @methods );
done_testing();
