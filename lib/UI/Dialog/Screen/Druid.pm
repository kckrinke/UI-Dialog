package UI::Dialog::Screen::Druid;
use strict;
use warnings;
use diagnostics;
use constant { TRUE => 1, FALSE => 0 };

BEGIN {
  use vars qw($VERSION);
  $VERSION = '1.12';
}

use UI::Dialog;

# Example Usage
#
# my $druid = new UI::Dialog::Screen::Druid
#   ( dialog => $DIALOG,
#     title => 'druid walkthrough'
#   );
# $druid->add_yesno_step('bool0',"Boolean 0");
# $druid->add_yesno_step('bool1',"Boolean 1");
# my (%answers) = $druid->perform();
#

sub new {
    my ($class, %args) = @_;
    unless (exists $args{dialog}) {
      $args{dialog} = new UI::Dialog
         (
          title => (defined $args{title}) ? $args{title} : '',
          backtitle => (defined $args{backtitle}) ? $args{backtitle} : '',
          height => (defined $args{height}) ? $args{height} : 20,
          width => (defined $args{width}) ? $args{width} : 65,
          listheight => (defined $args{listheight}) ? $args{listheight} : 5,
          order => (defined $args{order}) ? $args{order} : undef,
          PATH => (defined $args{PATH}) ? $args{PATH} : undef,
          beepbefore => (defined $args{beepbefore}) ? $args{beepbefore} : undef,
          beepafter => (defined $args{beepafter}) ? $args{beepafter} : undef,
         );
    }
    $args{performance} = [] unless exists $args{performance};
    return bless { %args }, $class;
}

#: not used yet, not sure keys being forced unique isn't too rigid
#
sub __verify_unique_tag {
  my ($self,$tag) = @_;
  if (grep {m!^\Q$tag\E$!} keys %{$self->{performance}}) {
    return FALSE; # exists already, not unique tag
  }
  # doesn't exist, is unique tag
  return TRUE;
}

#: $druid->add_input_step( "key", "Label text", "Default text");
#: Add a text-input step to the performance
#
sub add_input_step {
  my ($self,$tag,$text,$default) = @_;
  push( @{$self->{performance}},
        { type=>"input",
          tag=>$tag,
          text=>$text,
          default=>defined $default ? $default : '',
        }
      );
}

#: $druid->add_password_step( "key", "Label text" );
#: Add a password step to the performance
#
sub add_password_step {
  my ($self,$tag,$text) = @_;
  push( @{$self->{performance}},
        { type=>"password",
          tag=>$tag,
          text=>$text
        }
      );
}

#: $druid->add_menu_step( "key", "Label text", [qw|opt1 opt2 op3|] );
#: Add a menu select step to the performance
#
sub add_menu_step {
  my ($self,$tag,$text,$options) = @_;
  push( @{$self->{performance}},
        { type=>"menu",
          tag=>$tag,
          text=>$text,
          options=>$options
        }
      );
}

#: $druid->add_yesno_step( "key", "Label text" );
#: Add a yesno step to the performance
#
sub add_yesno_step {
  my ($self,$tag,$text) = @_;
  push( @{$self->{performance}},
        { type=>"yesno",
          tag=>$tag,
          text=>$text
        }
      );
}

#: my (%answers) = $druid->perform();
#: Show the performance! Walk the user to the druid's step :)
#
sub perform {
  my ($self) = @_;
  my $key = undef;
  my %answers = ();
  foreach my $step ( @{$self->{performance}} ) {
    $key = $step->{tag};
    my $r = undef;
    # yesno questions
    if ($step->{type} eq "yesno") {
      $r = $self->{dialog}->yesno
        ( title => $step->{tag},
          text => $step->{text}
        );
      goto PERFORM_STEP_FAILURE
        if $self->{dialog}->state() eq "ESC";
    }
    # text-input questions
    elsif ($step->{type} eq "input") {
      my $default = defined $step->{default} ? $step->{default} : '';
      foreach my $key (keys %answers) {
        my $val = $answers{$key};
        if ($default =~ m!\{\{\Q${key}\E\}\}!mg) {
          $default =~ s!\{\{\Q${key}\E\}\}!${val}!g;
        }
      }
      foreach my $step (@{$self->{performance}}) {
        if (exists $step->{default}) {
          my $key = $step->{tag};
          my $val = $step->{default};
          if ($default =~ m!\{\{\Q${key}\E\}\}!mg) {
            $default =~ s!\{\{\Q${key}\E\}\}!${val}!g;
          }
        }
      }
      $r = $self->{dialog}->inputbox
        ( title => $step->{tag},
          text => $step->{text},
          entry => $default
        );
      goto PERFORM_STEP_FAILURE
        if $self->{dialog}->state() ne "OK";
    }
    # password questions
    elsif ($step->{type} eq "password") {
      $r = $self->{dialog}->password
        ( title => $step->{tag},
          text => $step->{text}
        );
      goto PERFORM_STEP_FAILURE
        if $self->{dialog}->state() ne "OK";
    }
    # menu questions
    elsif ($step->{type} eq "menu") {
      my @list = ();
      my $count = 0;
      foreach (@{$step->{options}}) {
        $count++;
        push(@list,$count,$_);
      }
      $r = $self->{dialog}->menu
        ( title => $step->{tag},
          text => $step->{text},
          list => \@list
        );
      goto PERFORM_STEP_FAILURE
        if $self->{dialog}->state() ne "OK";
      $r = $step->{options}[$r-1];
    }
    $answers{$key} = $r;
  }
  return wantarray ? %answers : \%answers;
 PERFORM_STEP_FAILURE:
  my %aborted = (aborted=>1,key=>$key);
  return wantarray ? %aborted : \%aborted;
}


1; # END OF UI::Dialog::Screen::Druid
