use Test::More;
BEGIN { use_ok( 'UI::Dialog::Console' ); }
require_ok( 'UI::Dialog::Console' );

# #########################

my $obj = UI::Dialog::Console->new();
isa_ok( $obj, 'UI::Dialog::Console' );

my @methods = qw( new state ra rs rv nautilus xosd beep clear
                  yesno msgbox inputbox password textbox menu
                  checklist radiolist fselect dselect );
can_ok( 'UI::Dialog::Console', @methods );
done_testing();
