package UI::Dialog::Backend::XDialog;
###############################################################################
#  Copyright (C) 2004-2016  Kevin C. Krinke <kevin@krinke.ca>
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
###############################################################################
use 5.006;
use strict;
use warnings;
use Carp;
use FileHandle;
use File::Basename;
use Cwd qw( abs_path );
use UI::Dialog::Backend;

BEGIN {
  use vars qw( $VERSION @ISA );
  @ISA = qw( UI::Dialog::Backend );
  $VERSION = '1.13';
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Constructor Method
#:

sub new {
  my $proto = shift();
  my $class = ref($proto) || $proto;
  my $cfg = ((ref($_[0]) eq "HASH") ? $_[0] : (@_) ? { @_ } : {});
  my $self = {};
  bless($self, $class);
  $self->{'_state'} = {};
  $self->{'_opts'} = {};

	#: Dynamic path discovery...
	my $CFG_PATH = $cfg->{'PATH'};
	if ($CFG_PATH) {
		if (ref($CFG_PATH) eq "ARRAY") {
      $self->{'PATHS'} = $CFG_PATH;
    }
		elsif ($CFG_PATH =~ m!:!) {
      $self->{'PATHS'} = [ split(/:/,$CFG_PATH) ];
    }
		elsif (-d $CFG_PATH) {
      $self->{'PATHS'} = [ $CFG_PATH ];
    }
	}
  elsif ($ENV{'PATH'}) {
    $self->{'PATHS'} = [ split(/:/,$ENV{'PATH'}) ];
  }
	else {
    $self->{'PATHS'} = '';
  }

  $self->{'_opts'}->{'debug'} = $cfg->{'debug'} || undef();

	$self->{'_opts'}->{'literal'} = $cfg->{'literal'} || 0;

  $self->{'_opts'}->{'XDIALOG_HIGH_DIALOG_COMPAT'} = 1
    unless not $cfg->{'XDIALOG_HIGH_DIALOG_COMPAT'};

  $self->{'_opts'}->{'callbacks'} = $cfg->{'callbacks'} || undef();
  #  --wmclass <name>
  $self->{'_opts'}->{'wmclass'} = $cfg->{'wmclass'} || undef();
  #  --rc-file <gtkrc filename>
  $self->{'_opts'}->{'rcfile'} = $cfg->{'rcfile'} || undef();
  #  --backtitle <backtitle>
  $self->{'_opts'}->{'backtitle'} = $cfg->{'backtitle'} || undef();
  #  --title <title>
  $self->{'_opts'}->{'title'} = $cfg->{'title'} || undef();
  #  --allow-close | --no-close
  $self->{'_opts'}->{'allowclose'} = $cfg->{'allowclose'} || 0;
  $self->{'_opts'}->{'noclose'} = $cfg->{'noclose'} || 0;
  #  --screen-center | --under-mouse | --auto-placement
  $self->{'_opts'}->{'screencenter'} = $cfg->{'screencenter'} || 0;
  $self->{'_opts'}->{'undermouse'} = $cfg->{'undermouse'} || 0;
  $self->{'_opts'}->{'autoplacement'} = $cfg->{'autoplacement'} || 0;
  #  --center | --right | --left | --fill
  $self->{'_opts'}->{'center'} = $cfg->{'center'} || 0;
  $self->{'_opts'}->{'right'} = $cfg->{'right'} || 0;
  $self->{'_opts'}->{'left'} = $cfg->{'left'} || 0;
  $self->{'_opts'}->{'fill'} = $cfg->{'fill'} || 0;
  #  --no-wrap | --wrap
  $self->{'_opts'}->{'nowrap'} = $cfg->{'nowrap'} || 0;
  $self->{'_opts'}->{'wrap'} = $cfg->{'wrap'} || 0;
  #  --cr-wrap | --no-cr-wrap
  $self->{'_opts'}->{'crwrap'} = $cfg->{'crwrap'} || 0;
  $self->{'_opts'}->{'nocrwrap'} = $cfg->{'nocrwrap'} || 0;
  #  --buttons-style default|icon|text
  $self->{'_opts'}->{'buttonsstyle'} = $cfg->{'buttonsstyle'} || 'default';
  #  --fixed-font (tailbox, textbox, and editbox)
  $self->{'_opts'}->{'fixedfont'} = $cfg->{'fixedfont'} || 0;
  #  --editable (combobox)
  $self->{'_opts'}->{'editable'} = $cfg->{'editable'} || 0;
  #  --time-stamp | --date-stamp (logbox)
  $self->{'_opts'}->{'timestamp'} = $cfg->{'timestamp'} || 0;
  $self->{'_opts'}->{'datestamp'} = $cfg->{'datestamp'} || 0;
  #  --reverse (logbox)
  $self->{'_opts'}->{'reverse'} = $cfg->{'reverse'} || 0;
  #  --keep-colors (logbox)
  $self->{'_opts'}->{'keepcolors'} = $cfg->{'keepcolours'} || $cfg->{'keepcolors'} || 0;
  #  --interval <timeout> (input(s) boxes, combo box, range(s) boxes, spin(s) boxes, list boxes, menu box, treeview, calendar, timebox)
  $self->{'_opts'}->{'interval'} = $cfg->{'interval'} || 0;
  #  --no-tags (menubox, checklist and radiolist)
  $self->{'_opts'}->{'notags'} = $cfg->{'notags'} || 0;
  #  --item-help (menubox, checklist, radiolist, buildlist and treeview)
  $self->{'_opts'}->{'itemhelp'} = $cfg->{'itemhelp'} || 0;
  #  --default-item <tag> (menubox)
  $self->{'_opts'}->{'defaultitem'} = $cfg->{'defaultitem'} || undef();
  #  --icon <xpm filename> (textbox, editbox, tailbox, logbox, fselect and dselect)
  $self->{'_opts'}->{'icon'} = $cfg->{'icon'} || undef();
  #  --no-ok (tailbox and logbox)
  $self->{'_opts'}->{'nook'} = $cfg->{'nook'} || 0;
  #  --no-cancel (infobox, gauge and progress)
  $self->{'_opts'}->{'nocancel'} = $cfg->{'nocancel'} || 0;
  #  --no-buttons (textbox, tailbox, logbox, infobox  fselect and dselect)
  $self->{'_opts'}->{'nobuttons'} = $cfg->{'nobuttons'} || 0;
  #  --default-no !(wizard)
  $self->{'_opts'}->{'defaultno'} = $cfg->{'defaultno'} || 0;
  #  --wizard !(msgbox, infobox, gauge and progress)
  $self->{'_opts'}->{'wizard'} = $cfg->{'wizard'} || 0;
  #  --help <help> (infobox, gauge and progress)
  $self->{'_opts'}->{'help'} = $cfg->{'help'} || undef();
  #  --print <printer> (textbox, editbox and tailbox)
  $self->{'_opts'}->{'print'} = $cfg->{'print'} || undef();
  #  --check <label> !(infobox, gauge and progress)
  $self->{'_opts'}->{'check'} = $cfg->{'check'} || undef();
  #  --ok-label <label> !(wizard)
  $self->{'_opts'}->{'oklabel'} = $cfg->{'oklabel'} || undef();
  #  --cancel-label <label> !(wizard)
  $self->{'_opts'}->{'cancellabel'} = $cfg->{'cancellabel'} || undef();
  #  --beep | --beep-after (all)
  $self->{'_opts'}->{'beepbin'} = $cfg->{'beepbin'} || $self->_find_bin('beep') || '/usr/bin/beep';
  $self->{'_opts'}->{'beepbefore'} = $cfg->{'beepbefore'} || 0;
  $self->{'_opts'}->{'beepafter'} = $cfg->{'beepafter'} || 0;
  #  --begin <Yorg> <Xorg> (all)
  $self->{'_opts'}->{'begin'} = $cfg->{'begin'} || undef(); #: 'begin' => [$y,$x]
  #  --ignore-eof (infobox and gauge)
  $self->{'_opts'}->{'ignoreeof'} = $cfg->{'ignoreeof'} || 0;
  #  --smooth (tailbox and logbox)
  $self->{'_opts'}->{'smooth'} = $cfg->{'smooth'} || 0;

  #: \/we handle these internally\/
  #  --stderr | --stdout
  #  --separator <character> | --separate-output
  #: ^^we handle these internally^^

  $self->{'_opts'}->{'bin'} ||= $self->_find_bin('Xdialog');
  unless (-x $self->{'_opts'}->{'bin'}) {
		croak("the Xdialog binary could not be found.");
  }

  #: to determin upper limits use:
  #  --print-maxsize
  #: STDOUT| MaxSize: \d+(width), \d+(height)
  $self->{'_opts'}->{'width'} = $cfg->{'width'} || 0;
  $self->{'_opts'}->{'height'} = $cfg->{'height'} || 0;
  $self->{'_opts'}->{'listheight'} = $cfg->{'listheight'} || $cfg->{'menuheight'} || 5;
  $self->{'_opts'}->{'percentage'} = $cfg->{'percentage'} || 1;

  $self->{'_opts'}->{'autoclear'} = $cfg->{'autoclear'} || 0;
  $self->{'_opts'}->{'clearbefore'} = $cfg->{'clearbefore'} || 0;
  $self->{'_opts'}->{'clearafter'} = $cfg->{'clearafter'} || 0;
  $self->{'_opts'}->{'timeout'} = $cfg->{'timeout'} || 0;
  $self->{'_opts'}->{'wait'} = $cfg->{'wait'} || 0;

  $self->{'_opts'}->{'trust-input'} =
    ( exists $cfg->{'trust-input'}
      && $cfg->{'trust-input'}==1
    ) ? 1 : 0;

  return($self);
}




#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Private Methods
#:
my $SIG_CODE = {'PROGRESS'=>{},'GAUGE'=>{}};
sub _del_progress {
  my $CODE = $SIG_CODE->{'PROGRESS'}->{$$};
  unless (not ref($CODE)) {
		delete($CODE->{'_PROGRESS'});
		$CODE->rv('1');
		$CODE->rs('null');
		$CODE->ra('null');
		$SIG_CODE->{$$} = "";
  }
}
sub _del_gauge {
  my $CODE = $SIG_CODE->{'GAUGE'}->{$$};
  unless (not ref($CODE)) {
		delete($CODE->{'_GAUGE'});
		$CODE->rv('1');
		$CODE->rs('null');
		$CODE->ra('null');
		$SIG_CODE->{$$} = "";
  }
}

sub append_format_base {
  my ($self,$args,$fmt) = @_;
  $fmt = $self->append_format_check($args,$fmt,'title','--title {{title}}');
  $fmt = 'XDIALOG_HIGH_DIALOG_COMPAT="1" ' . $fmt
    if $args->{'XDIALOG_HIGH_DIALOG_COMPAT'};

  $fmt->append_format_check($args,$fmt,"editable","--editable");
  $fmt->append_format_check($args,$fmt,"center","--center");
  $fmt->append_format_check($args,$fmt,"right","--right");
  $fmt->append_format_check($args,$fmt,"left","--left");
  $fmt->append_format_check($args,$fmt,"fill","--fill");
  $fmt->append_format_check($args,$fmt,"wrap","--wrap");
  $fmt->append_format_check($args,$fmt,"crwrap","--crwrap");
  $fmt->append_format_check($args,$fmt,"nocrwrap","--nocrwrap");
  $fmt->append_format_check($args,$fmt,"reverse","--reverse");
  $fmt->append_format_check($args,$fmt,"wizard","--wizard");
  $fmt->append_format_check($args,$fmt,"smooth","--smooth");

  $args->{'no-wrap'} ||= $args->{'nowrap'};
  $fmt->append_format_check($args,$fmt,"no-wrap","--no-wrap");
  $args->{'allow-close'} ||= $args->{'allowclose'};
  $fmt->append_format_check($args,$fmt,"allow-close","--allow-close");
  $args->{'no-close'} ||= $args->{'noclose'};
  $fmt->append_format_check($args,$fmt,"no-close","--no-close");
  $args->{'screen-center'} ||= $args->{'screencenter'};
  $fmt->append_format_check($args,$fmt,"screen-center","--screen-center");
  $args->{'under-mouse'} ||= $args->{'undermouse'};
  $fmt->append_format_check($args,$fmt,"under-mouse","--under-mouse");
  $args->{'auto-placement'} ||= $args->{'autoplacement'};
  $fmt->append_format_check($args,$fmt,"auto-placement","--auto-placement");
  $args->{'fixed-font'} ||= $args->{'fixedfont'};
  $fmt->append_format_check($args,$fmt,"fixed-font","--fixed-font");
  $args->{'time-stamp'} ||= $args->{'timestamp'};
  $fmt->append_format_check($args,$fmt,"time-stamp","--time-stamp");
  $args->{'date-stamp'} ||= $args->{'datestamp'};
  $fmt->append_format_check($args,$fmt,"date-stamp","--date-stamp");
  $args->{'keep-colors'} ||= $args->{'keep-colours'} || $args->{'keepcolors'} || $args->{'keepcolours'};
  $fmt->append_format_check($args,$fmt,"keep-colors","--keep-colors");
  $args->{'no-tags'} ||= $args->{'notags'};
  $fmt->append_format_check($args,$fmt,"no-tags","--no-tags");
  $args->{'item-help'} ||= $args->{'itemhelp'};
  $fmt->append_format_check($args,$fmt,"item-help","--item-help");
  $args->{'no-ok'} ||= $args->{'nook'};
  $fmt->append_format_check($args,$fmt,"no-ok","--no-ok");
  $args->{'no-cancel'} ||= $args->{'nocancel'};
  $fmt->append_format_check($args,$fmt,"no-cancel","--no-cancel");
  $args->{'no-buttons'} ||= $args->{'nobuttons'};
  $fmt->append_format_check($args,$fmt,"no-buttons","--no-buttons");
  $args->{'default-no'} ||= $args->{'defaultno'};
  $fmt->append_format_check($args,$fmt,"default-no","--default-no");
  $args->{'ignore-eof'} ||= $args->{'ignoreeof'};
  $fmt->append_format_check($args,$fmt,"ignore-eof","--ignore-eof");

  $fmt->append_format_check($args,$fmt,"wmclass","--wmclass {{wmclass}}");
  $fmt->append_format_check($args,$fmt,"title","--title {{title}}");
  $fmt->append_format_check($args,$fmt,"backtitle","--backtitle {{backtitle}}");
  $fmt->append_format_check($args,$fmt,"interval","--interval {{interval}}");
  $fmt->append_format_check($args,$fmt,"icon","--icon {{icon}}");
  $fmt->append_format_check($args,$fmt,"help","--help {{help}}");
  $fmt->append_format_check($args,$fmt,"print","--print {{print}}");
  $fmt->append_format_check($args,$fmt,"check",'--check {{check}}');

  $args->{'rc-file'} ||= $args->{'rcfile'};
  $fmt->append_format($fmt,'--rc-file "'.$args->{'rc-file'}.'"')
    unless not -r $args->{'rc-file'};

  $args->{'button-style'} ||= $args->{'buttonsstyle'};
  $fmt->append_format_check($args,$fmt,"button-style",'--button-style "'.$args->{'button-style'}.'"');
  $args->{'default-item'} ||= $args->{'defaultitem'};
  $fmt->append_format_check($args,$fmt,"default-item",'--default-item "'.$args->{'default-item'}.'"');
  $args->{'ok-label'} ||= $args->{'oklabel'};
  $fmt->append_format_check($args,$fmt,"ok-label",'--ok-label "'.$args->{'ok-label'}.'"');
  $args->{'cancel-label'} ||= $args->{'cancellabel'};
  $fmt->append_format_check($args,$fmt,"cancel-label",'--cancel-label "'.$args->{'cancel-label'}.'"');

  if (exists $args->{'begin'}) {
    my $begin = $args->{'begin'};
    if (ref($begin) eq "ARRAY") {
      $fmt = $self->append_format($fmt,'--begin '.$begin->[0].' '.$begin->[1]);
    }
  }

  return $fmt;
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: State Methods (override inherited)
#:

#: report on the state of the last widget.
sub state {
  my $self = shift();
  my $rv = $self->rv() || 0;
  $self->_debug((join(" | ",(caller())))." > state() > is: ".($rv||'NULL'),2);
  if ($rv == 1 or $rv == 129) {
		return("CANCEL");
  }
  elsif ($rv == 2) {
		return("HELP");
  }
  elsif ($rv == 3) {
		return("PREVIOUS");
  }
  elsif ($rv == 254) {
		return("ERROR");
  }
  elsif ($rv == 255) {
		return("ESC");
  }
  elsif (not $rv or $rv =~ /^null$/i) {
		return("OK");
  }
  else {
		return("UNKNOWN(".$rv.")");
  }
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public Methods
#:

#  --combobox    <text> <height> <width> <item1> ... <itemN>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display a dropdown list that's editable
sub combobox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --combobox {{text}} {{height}} {{width}} {{list}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$selected) = $self->command_string($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra($selected);
		$self->rs($selected);
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv);
}


#  --rangebox    <text> <height> <width> <min value> <max value> [<default value>]
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display a slider bar with a preset range.
sub rangebox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);


  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--rangebox {{text}} {{height}} {{width}} {{min}} {{max}} {{def}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      min => $self->make_kvl($args,($args->{'min'}||'0')),
      max => $self->make_kvl($args,($args->{'max'}||'100')),
      def => $self->make_kvl($args,($args->{'def'}||'0')),
    );

  my ($rv,$selected) = $self->command_string($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra($selected);
		$self->rs($selected);
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv);
}

#  --2rangesbox  <text> <height> <width> <label1> <min1> <max1> <def1> <label2> <min2> <max2> <def2>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display two slider bars with preset ranges and labels
sub rangesbox2 {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --2rangesbox {{text}} {{height}} {{width}}');
  $fmt = $self->append_format($fmt,'{{label1}} {{min1}} {{max1}} {{def1}}');
  $fmt = $self->append_format($fmt,'{{label2}} {{min2}} {{max2}} {{def2}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      label1 => $self->make_kvl($args,($args->{'label1'}||'')),
      min1 => $self->make_kvl($args,($args->{'min1'}||'0')),
      max1 => $self->make_kvl($args,($args->{'max1'}||'100')),
      def1 => $self->make_kvl($args,($args->{'def1'}||'0')),
      label2 => $self->make_kvl($args,($args->{'label2'}||'')),
      min2 => $self->make_kvl($args,($args->{'min2'}||'0')),
      max2 => $self->make_kvl($args,($args->{'max2'}||'100')),
      def2 => $self->make_kvl($args,($args->{'def2'}||'0')),
    );

  my ($rv,$selected) = $self->command_array($command);

  $self->rv($rv||'null');
  $self->rs('null');
  $self->ra('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra(@$selected);
		$self->rs(join("\n",@$selected));
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv) unless ref($this_rv) eq "ARRAY";
  return(@{$this_rv});
}

#  --3rangesbox  <text> <height> <width> <label1> <min1> <max1> <def1> <label2> <min2> <max2> <def2> <label3> <min3> <max3> <def3>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display three slider bars with preset ranges and labels
sub rangesbox3 {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --3rangesbox {{text}} {{height}} {{width}}');
  $fmt = $self->append_format($fmt,'{{label1}} {{min1}} {{max1}} {{def1}}');
  $fmt = $self->append_format($fmt,'{{label2}} {{min2}} {{max2}} {{def2}}');
  $fmt = $self->append_format($fmt,'{{label3}} {{min3}} {{max3}} {{def3}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      label1 => $self->make_kvl($args,($args->{'label1'}||'')),
      min1 => $self->make_kvl($args,($args->{'min1'}||'0')),
      max1 => $self->make_kvl($args,($args->{'max1'}||'100')),
      def1 => $self->make_kvl($args,($args->{'def1'}||'0')),
      label2 => $self->make_kvl($args,($args->{'label2'}||'')),
      min2 => $self->make_kvl($args,($args->{'min2'}||'0')),
      max2 => $self->make_kvl($args,($args->{'max2'}||'100')),
      def2 => $self->make_kvl($args,($args->{'def2'}||'0')),
      label3 => $self->make_kvl($args,($args->{'label3'}||'')),
      min3 => $self->make_kvl($args,($args->{'min3'}||'0')),
      max3 => $self->make_kvl($args,($args->{'max3'}||'100')),
      def3 => $self->make_kvl($args,($args->{'def3'}||'0')),
    );

  my ($rv,$selected) = $self->command_array($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra(@$selected);
		$self->rs(join("\n",@$selected));
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv) unless ref($this_rv) eq "ARRAY";
  return(@{$this_rv});
}

#  --spinbox     <text> <height> <width> <min> <max> <def> <label>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display a spin box (a number with up/down buttons) with preset ranges
sub spinbox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $self->{'min'} ||= $self->{'min1'};
  $self->{'max'} ||= $self->{'max1'};
  $self->{'def'} ||= $self->{'def1'};
  $self->{'label'} ||= $self->{'label1'};
  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --spinbox {{text}} {{height}} {{width}}');
  $fmt = $self->append_format($fmt,'{{min}} {{max}} {{def}} {{label}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      min => $self->make_kvl($args,($args->{'min'}||'0')),
      max => $self->make_kvl($args,($args->{'max'}||'100')),
      def => $self->make_kvl($args,($args->{'def'}||'0')),
      label => $self->make_kvl($args,($args->{'label'}||'')),
    );

  my ($rv,$selected) = $self->command_string($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra($selected);
		$self->rs($selected);
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv);
}

#  --2spinsbox   <text> <height> <width> <min1> <max1> <def1> <label1> <min2> <max2> <def2> <label2>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display two spin boxes with preset ranges and labels
sub spinsbox2 {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --2spinsbox {{text}} {{height}} {{width}}');
  $fmt = $self->append_format($fmt,'{{min1}} {{max1}} {{def1}} {{label1}}');
  $fmt = $self->append_format($fmt,'{{min2}} {{max2}} {{def2}} {{label2}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      label1 => $self->make_kvl($args,($args->{'label1'}||'')),
      min1 => $self->make_kvl($args,($args->{'min1'}||'0')),
      max1 => $self->make_kvl($args,($args->{'max1'}||'100')),
      def1 => $self->make_kvl($args,($args->{'def1'}||'0')),
      label2 => $self->make_kvl($args,($args->{'label2'}||'')),
      min2 => $self->make_kvl($args,($args->{'min2'}||'0')),
      max2 => $self->make_kvl($args,($args->{'max2'}||'100')),
      def2 => $self->make_kvl($args,($args->{'def2'}||'0')),
    );

  my ($rv,$selected) = $self->command_array($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra(@$selected);
		$self->rs(join("\n",@$selected));
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv) unless ref($this_rv) eq "ARRAY";
  return(@{$this_rv});
}

#  --3spinsbox   <text> <height> <width> <text> <height> <width> <min1> <max1> <def1> <label1> <min2> <max2> <def2> <label2> <min3> <max3> <def3> <label3>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display three spin boxes with preset ranges and labels
sub spinsbox3 {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --3spinsbox {{text}} {{height}} {{width}}');
  $fmt = $self->append_format($fmt,'{{min1}} {{max1}} {{def1}} {{label1}}');
  $fmt = $self->append_format($fmt,'{{min2}} {{max2}} {{def2}} {{label2}}');
  $fmt = $self->append_format($fmt,'{{min3}} {{max3}} {{def3}} {{label3}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      label1 => $self->make_kvl($args,($args->{'label1'}||'')),
      min1 => $self->make_kvl($args,($args->{'min1'}||'0')),
      max1 => $self->make_kvl($args,($args->{'max1'}||'100')),
      def1 => $self->make_kvl($args,($args->{'def1'}||'0')),
      label2 => $self->make_kvl($args,($args->{'label2'}||'')),
      min2 => $self->make_kvl($args,($args->{'min2'}||'0')),
      max2 => $self->make_kvl($args,($args->{'max2'}||'100')),
      def2 => $self->make_kvl($args,($args->{'def2'}||'0')),
      label3 => $self->make_kvl($args,($args->{'label3'}||'')),
      min3 => $self->make_kvl($args,($args->{'min3'}||'0')),
      max3 => $self->make_kvl($args,($args->{'max3'}||'100')),
      def3 => $self->make_kvl($args,($args->{'def3'}||'0')),
    );

  my ($rv,$selected) = $self->command_array($command);

  $self->rv($rv||'null');
  $self->rs('null');
  $self->ra('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra(@$selected);
		$self->rs(join("\n",@$selected));
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv) unless ref($this_rv) eq "ARRAY";
  return(@{$this_rv});
}

#  --buildlist   <text> <height> <width> <list height> <tag1> <item1> <status1> {<help1>}...
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display a two paned box by which the user can organize a list of items
sub buildlist {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $self->{'buildlist'} ||= 'buildlist';
  $self->{'listheight'} ||= $self->{'menuheight'};

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --'.$self->{'buildlist'});
  $fmt = $self->append_format('{{text}} {{height}} {{width}} {{listheight}} {{list}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$selected) = $self->command_array($command);

  $self->rv($rv||'null');
  $self->rs('null');
  $self->ra('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra(@$selected);
		$self->rs(join("\n",@$selected));
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv) unless ref($this_rv) eq "ARRAY";
  return(@{$this_rv});
}

#  --treeview    <text> <height> <width> <list height> <tag1> <item1> <status1> <item_depth1> {<help1>}...
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display a tree view of items
sub treeview {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $self->{'treeview'} ||= 'treeview';
  $self->{'listheight'} ||= $self->{'menuheight'};

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --'.$self->{'treeview'});
  $fmt = $self->append_format('{{text}} {{height}} {{width}} {{listheight}} {{list}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$selected) = $self->command_string($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra($selected);
		$self->rs($selected);
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv);
}

#  --calendar    <text> <height> <width> <day> <month> <year>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display a calendar with a preset date
sub calendar {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  $args->{'day'}   ||= '1';
  $args->{'month'} ||= '1';
  $args->{'year'}  ||= '1970';

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --calendar {{text}} {{height}} {{width}} {{day}} {{month}} {{year}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$selected) = $self->command_string($command);
  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		chomp($selected);
		$self->ra(split(/\//,$selected));
		$self->rs($selected);
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv);
}

#  --timebox     <text> <height> <width>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display a time box
sub timebox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --timebox {{text}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$selected) = $self->command_string($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra(split(/\:/,$selected));
		$self->rs($selected);
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv);
}

#  --yesno       <text> <height> <width>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Ask a binary question (Yes/No)
sub yesno {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--yesno {{text}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my $rv = $self->command_state($command);

  $self->rv($rv||'null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$self->ra("NO");
		$self->rs("NO");
		$this_rv = 0;
  }
  else {
		$self->ra("YES");
		$self->rs("YES");
		$this_rv = 1;
  }
  $self->_post($args);
  return($this_rv);
}

#  --inputbox    <text> <height> <width> [<init>]
#  --2inputsbox  <text> <height> <width> <label1> <init1> <label2> <init2>
#  --3inputsbox  <text> <height> <width> <label1> <init1> <label2> <init2> <label3> <init3>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Text entry
sub inputbox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  my $val = $args->{'inputs'} || $args->{'password'} || 1;

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  if ($val > 1) {
    $fmt = $self->append_format($fmt,'--separate-output');
  }
  $fmt = $self->append_format_check($args,$fmt,'password','--password');
  $fmt = $self->append_format_check($args,$fmt,'password','--password') if $val > 1;
  $fmt = $self->append_format_check($args,$fmt,'password','--password') if $val > 2;

  my $opbox = '--inputbox';
  $opbox = '--2inputsbox' if $val == 2;
  $opbox = '--3inputsbox' if $val == 3;

  $fmt = $self->append_format($fmt,$opbox.' {{text}} {{height}} {{width}}');
  $fmt = $self->append_format($fmt,'"'.($args->{'entry'}||$args->{'init'}).'"') if $val == 1;
  $fmt = $self->append_format($fmt,'"'.($args->{'label1'}||'').'"') if $val > 1;
  $fmt = $self->append_format($fmt,'"'.($args->{'input1'}||'').'"') if $val > 1;
  $fmt = $self->append_format($fmt,'"'.($args->{'label2'}||'').'"') if $val >= 2;
  $fmt = $self->append_format($fmt,'"'.($args->{'input2'}||'').'"') if $val >= 2;
  $fmt = $self->append_format($fmt,'"'.($args->{'label3'}||'').'"') if $val >= 3;
  $fmt = $self->append_format($fmt,'"'.($args->{'input3'}||'').'"') if $val >= 3;

  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$text);
  if ($val == 1) {
		($rv,$text) = $self->command_string($command);
  }
  else {
		($rv,$text) = $self->command_array($command);
  }

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		if ($val == 1) {
			$self->ra($text);
			$self->rs($text);
		}
    else {
			$self->ra(@$text);
			$self->rs(join("\n",@$text));
		}
		$this_rv = $text;
  }
  $self->_post($args);
  return($this_rv) unless ref($this_rv) eq "ARRAY";
  return(@{$this_rv});
}
sub inputsbox2 {
  my $self = shift();
  return($self->inputbox('caller',((caller(1))[3]||'main'),@_,'inputs',2));
}
sub inputsbox3 {
  my $self = shift();
  return($self->inputbox('caller',((caller(1))[3]||'main'),@_,'inputs',3));
}
sub password {
  my $self = shift();
  return($self->inputbox('caller',((caller(1))[3]||'main'),@_,'password',1,'inputs',1));
}
sub passwords2 {
  my $self = shift();
  return($self->inputbox('caller',((caller(1))[3]||'main'),@_,'password',1,'inputs',2));
}
sub passwords3 {
  my $self = shift();
  return($self->inputbox('caller',((caller(1))[3]||'main'),@_,'password',1,'inputs',3));
}

#  --msgbox      <text> <height> <width>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Text box
sub msgbox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $args->{'msgbox'} ||= 'msgbox';

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--'.$args->{'msgbox'});
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}}');
  my $wait = ($args->{'wait'} ? $args->{'wait'}*1000 : ($args->{'timeout'}||'5000'));
  $fmt = $self->append_format($fmt,'"'.$wait.'"') if $args->{'msgbox'} eq 'infobox';
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my $rv = $self->command_state($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$this_rv = 1;
  }
  $self->_post($args);
  return($this_rv);
}

#  --infobox     <text> <height> <width> [<timeout>]
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: same as msgbox but destroy's itself with timeout...
sub infobox {
  my $self = shift();
  return($self->msgbox('caller',((caller(1))[3]||'main'),@_,'msgbox','infobox'));
}

#  --editbox     <file> <height> <width>
#  --tailbox     <file> <height> <width>
#  --logbox      <file> <height> <width>
#  --textbox     <file> <height> <width>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: File box
sub textbox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $args->{'textbox'} ||= 'textbox';
  $args->{'filename'} ||= $args->{'path'};

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--'.$args->{'textbox'});
  $fmt = $self->append_format($fmt,'{{filename}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      filename => $self->make_kvl($args,$args->{'filename'}),
    );

  my ($rv,$text) = $self->command_string($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra(($text) ? [ $text ] : 'null');
		$self->rs($text||'null');
		$this_rv = $text || 1;
  }
  $self->_post($args);
  return($this_rv);
}
sub editbox {
  my $self = shift();
  return($self->textbox('caller',((caller(1))[3]||'main'),@_,'textbox','editbox'));
}
sub logbox {
  my $self = shift();
  return($self->textbox('caller',((caller(1))[3]||'main'),@_,'textbox','logbox'));
}
sub tailbox {
  my $self = shift();
  return($self->textbox('caller',((caller(1))[3]||'main'),@_,'textbox','tailbox'));
}

#  --menubox     <text> <height> <width> <menu height> <tag1> <item1> {<help1>}...
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Lists
sub menu {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --menu');
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}} {{listheight}} {{list}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$selected) = $self->command_string($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra($selected);
		$self->rs($selected);
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv);
}

#  --checklist   <text> <height> <width> <list height> <tag1> <item1> <status1> {<help1>}...
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: multiple selection list via checkbox widgets
sub checklist {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $self->{'checklist'} ||= 'checklist';

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --'.$self->{'checklist'});
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}} {{listheight}} {{list}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$selected) = $self->command_array($command);

  $self->rv($rv||'null');
  $self->rs('null');
  $self->ra('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra(@$selected);
		$self->rs(join("\n",@$selected));
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv) unless ref($this_rv) eq "ARRAY";
  return(@{$this_rv});
}

#  --radiolist   <text> <height> <width> <list height> <tag1> <item1> <status1> {<help1>}...
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: display a list via the radiolist widget
sub radiolist {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $self->{'radiolist'} ||= 'radiolist';

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output --'.$self->{'radiolist'});
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}} {{listheight}} {{list}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$selected) = $self->command_string($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra($selected);
		$self->rs($selected);
		$this_rv = $selected;
  }
  $self->_post($args);
  return($this_rv);
}

#  --fselect     <file> <height> <width>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: file select
sub fselect {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  $args->{'path'} ||= abs_path();

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--fselect');
  $fmt = $self->append_format($fmt,'{{path}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      path => $self->make_kvl($args,$args->{'path'}),
    );

  my ($rv,$file) = $self->command_string($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra($file);
		$self->rs($file);
		$this_rv = $file;
  }
  $self->_post($args);
  return($this_rv);
}

#  --dselect     <directory> <height> <width>
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: directory selector
sub dselect {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  $args->{'path'} ||= abs_path();

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--dselect');
  $fmt = $self->append_format($fmt,'{{path}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      path => $self->make_kvl($args,$args->{'path'}),
    );

  my ($rv,$file) = $self->command_string($command);

  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
		$this_rv = 0;
  }
  else {
		$self->ra($file);
		$self->rs($file);
		$this_rv = $file;
  }
  $self->_post($args);
  return($this_rv);
}

#  --gauge       <text> <height> <width> [<percent>]
#  --progress    <text> <height> <width> [<maxdots> [[-]<msglen>]]
#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: progress meter
sub progress_start {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $self->{'_PROGRESS'} ||= {};
  $self->{'_PROGRESS'}->{'ARGS'} = $args;

  if (defined $self->{'_PROGRESS'}->{'FH'}) {
		$self->rv(129);
		$self->_post($args);
		return(0);
  }

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--progress');
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}}');
  $fmt = $self->append_format($fmt,'"'.($args->{'maxdots'}||'').'"') if $args->{'maxdots'} or $args->{'msglen'};
  $fmt = $self->append_format($fmt,'"'.($args->{'msglen'}||'').'"') if $args->{'msglen'};
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  $self->{'_PROGRESS'}->{'PERCENT'} = ($args->{'percentage'} || '0');

  $self->_debug("command: ".$command,2);
  $self->{'_PROGRESS'}->{'FH'} = new FileHandle;
  $self->{'_PROGRESS'}->{'FH'}->open("| $command");
  my $rv = $? >> 8;
  $self->{'_PROGRESS'}->{'FH'}->autoflush(1);
  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
    $this_rv = 0;
  }
  else {
    $this_rv = 1;
  }
  return($this_rv);
}
sub gauge_start {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $self->{'_GAUGE'} ||= {};
  $self->{'_GAUGE'}->{'ARGS'} = $args;

  if (defined $self->{'_GAUGE'}->{'FH'}) {
		$self->rv(129);
		$self->_post($args);
		return(0);
  }
  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--progress');
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}} {{percentage}}');
  $fmt = $self->append_format($fmt,'"'.($args->{'msglen'}||'').'"') if $args->{'msglen'};
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      percentage => $self->make_kvl($args,($args->{'percentage'}||'0')),
    );

  $self->{'_GAUGE'}->{'PERCENT'} = ($args->{'percentage'} || '0');

  $self->_debug("command: ".$command,2);

  $self->{'_GAUGE'}->{'FH'} = new FileHandle;
  $self->{'_GAUGE'}->{'FH'}->open("| $command");
  my $rv = $? >> 8;
  $self->{'_GAUGE'}->{'FH'}->autoflush(1);
  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  my $this_rv;
  if ($rv && $rv >= 1) {
    $this_rv = 0;
  }
  else {
    $this_rv = 1;
  }
  return($this_rv);
}
sub progress_inc {
  my $self = $_[0];
  my $incr = $_[1] || 1;

  return(0) unless defined $self->{'_PROGRESS'}->{'FH'};

  my $fh = $self->{'_PROGRESS'}->{'FH'};
  $self->{'_PROGRESS'}->{'PERCENT'} += $incr;
  $SIG_CODE->{'PROGRESS'}->{$$} = $self; local $SIG{'PIPE'} = \&_del_progress;
  print $fh $self->{'_PROGRESS'}->{'PERCENT'}."\n";
  return(((defined $self->{'_PROGRESS'}->{'FH'}) ? 1 : 0));
}
sub gauge_inc {
  my $self = $_[0];
  my $incr = $_[1] || 1;

  return(0) unless defined $self->{'_GAUGE'}->{'FH'};

  my $fh = $self->{'_GAUGE'}->{'FH'};
  $self->{'_GAUGE'}->{'PERCENT'} += $incr;
  $SIG_CODE->{'GAUGE'}->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  print $fh $self->{'_GAUGE'}->{'PERCENT'}."\n";
  return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub progress_dec {
  my $self = $_[0];
  my $decr = $_[1] || 1;

  return(0) unless defined $self->{'_PROGRESS'}->{'FH'};

  my $fh = $self->{'_PROGRESS'}->{'FH'};
  $self->{'_PROGRESS'}->{'PERCENT'} -= $decr;
  $SIG_CODE->{'PROGRESS'}->{$$} = $self; local $SIG{'PIPE'} = \&_del_progress;
  print $fh $self->{'_PROGRESS'}->{'PERCENT'}."\n";
  return(((defined $self->{'_PROGRESS'}->{'FH'}) ? 1 : 0));
}
sub gauge_dec {
  my $self = $_[0];
  my $decr = $_[1] || 1;

  return(0) unless defined $self->{'_GAUGE'}->{'FH'};

  my $fh = $self->{'_GAUGE'}->{'FH'};
  $self->{'_GAUGE'}->{'PERCENT'} -= $decr;
  $SIG_CODE->{'GAUGE'}->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  print $fh $self->{'_GAUGE'}->{'PERCENT'}."\n";
  return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub progress_set {
  my $self = $_[0];
  my $perc = $_[1] || $self->{'_PROGRESS'}->{'PERCENT'} || 1;

  return(0) unless defined $self->{'_PROGRESS'}->{'FH'};

  my $fh = $self->{'_PROGRESS'}->{'FH'};
  $self->{'_PROGRESS'}->{'PERCENT'} = $perc;
  $SIG_CODE->{'PROGRESS'}->{$$} = $self; local $SIG{'PIPE'} = \&_del_progress;
  print $fh $self->{'_PROGRESS'}->{'PERCENT'}."\n";
  return(((defined $self->{'_PROGRESS'}->{'FH'}) ? 1 : 0));
}
sub gauge_set {
  my $self = $_[0];
  my $perc = $_[1] || $self->{'_GAUGE'}->{'PERCENT'} || 1;

  return(0) unless defined $self->{'_GAUGE'}->{'FH'};

  my $fh = $self->{'_GAUGE'}->{'FH'};
  $self->{'_GAUGE'}->{'PERCENT'} = $perc;
  $SIG_CODE->{'GAUGE'}->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  print $fh $self->{'_GAUGE'}->{'PERCENT'}."\n";
  return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub gauge_text {
  my $self = $_[0];
  my $mesg = $_[1] || return(0);

  return(0) unless defined $self->{'_GAUGE'}->{'FH'};

  my $fh = $self->{'_GAUGE'}->{'FH'};
  $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  print $fh "\nXXX\n\n".$mesg."\n\nXXX\n\n".$self->{'_GAUGE'}->{'PERCENT'}."\n";
  return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub progress_stop {
  my $self = $_[0];

  return(0) unless defined $self->{'_PROGRESS'}->{'FH'};

  my $args = $self->{'_PROGRESS'}->{'ARGS'};
  my $fh = $self->{'_PROGRESS'}->{'FH'};
  $SIG_CODE->{'PROGRESS'}->{$$} = $self; local $SIG{'PIPE'} = \&_del_progress;
  $self->{'_PROGRESS'}->{'FH'}->close();
  delete($self->{'_PROGRESS'}->{'FH'});
  delete($self->{'_PROGRESS'}->{'PERCENT'});
  delete($self->{'_PROGRESS'}->{'ARGS'});
  delete($self->{'_PROGRESS'});
  $self->rv('null');
  $self->rs('null');
  $self->ra('null');
  $self->_post($args);
  return(1);
}
sub gauge_stop {
  my $self = $_[0];

  return(0) unless defined $self->{'_GAUGE'}->{'FH'};

  my $args = $self->{'_GAUGE'}->{'ARGS'};
  my $fh = $self->{'_GAUGE'}->{'FH'};
  $SIG_CODE->{'GAUGE'}->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  $self->{'_GAUGE'}->{'FH'}->close();
  delete($self->{'_GAUGE'}->{'FH'});
  delete($self->{'_GAUGE'}->{'PERCENT'});
  delete($self->{'_GAUGE'}->{'ARGS'});
  delete($self->{'_GAUGE'});
  $self->rv('null');
  $self->rs('null');
  $self->ra('null');
  $self->_post($args);
  return(1);
}


1;
