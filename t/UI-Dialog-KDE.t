use Test::More;
BEGIN { use_ok( 'UI::Dialog::KDE' ); }
require_ok( 'UI::Dialog::KDE' );

# #########################

my $obj = UI::Dialog::KDE->new();
isa_ok( $obj, 'UI::Dialog::KDE' );

my @methods = qw( new state ra rs rv nautilus xosd beep clear
                  yesno msgbox inputbox password textbox menu
                  checklist radiolist fselect dselect );
can_ok( 'UI::Dialog::KDE', @methods );
done_testing();
