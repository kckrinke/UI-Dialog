package UI::Dialog::Backend::XDialog;
###############################################################################
#  Copyright (C) 2013  Kevin C. Krinke <kevin@krinke.ca>
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
use FileHandle;
use File::Basename;
use Carp;
use Cwd qw( abs_path );
use UI::Dialog::Backend;

BEGIN {
    use vars qw( $VERSION @ISA );
    @ISA = qw( UI::Dialog::Backend );
    $VERSION = '1.09';
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
		if (ref($CFG_PATH) eq "ARRAY") { $self->{'PATHS'} = $CFG_PATH; }
		elsif ($CFG_PATH =~ m!:!) { $self->{'PATHS'} = [ split(/:/,$CFG_PATH) ]; }
		elsif (-d $CFG_PATH) { $self->{'PATHS'} = [ $CFG_PATH ]; }
	} elsif ($ENV{'PATH'}) { $self->{'PATHS'} = [ split(/:/,$ENV{'PATH'}) ]; }
	else { $self->{'PATHS'} = ''; }

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
sub _mk_cmnd {
    my $self = shift();
    my $final = shift();
    my $cmnd = $self->{'_opts'}->{'bin'};
    my $args = $self->_merge_attrs(@_);

    $cmnd = 'XDIALOG_HIGH_DIALOG_COMPAT="1" ' . $cmnd
     unless not $args->{'XDIALOG_HIGH_DIALOG_COMPAT'};

    #  --wmclass <name>
    $cmnd .= ' --wmclass "' . $args->{'wmclass'} . '"' unless not $args->{'wmclass'};
    #  --rc-file <gtkrc filename>
    $cmnd .= ' --rc-file "' . $args->{'rcfile'} . '"' unless not $args->{'rcfile'} or not -r $args->{'rcfile'};
    #  --begin <Yorg> <Xorg> (all)
    $cmnd .= ' --begin "' . $args->{'begin'}->[0] . '" "' . $args->{'begin'}->[1] . '"'
     unless not $args->{'begin'} or not ref($args->{'begin'}) or ref($args->{'begin'}) ne "ARRAY";
    #  --editable (combobox)
    $cmnd .= ' --editable' unless not $args->{'editable'};
    #  --title <title>
    $cmnd .= ' --title "' . $args->{'title'} . '"'  unless not $args->{'title'};
    #  --backtitle <backtitle>
    $cmnd .= ' --backtitle "' . $args->{'backtitle'} . '"' unless not $args->{'backtitle'};
    #  --allow-close | --no-close
    $cmnd .= ' --allow-close' unless not $args->{'allow-close'} and not $args->{'allowclose'};
    $cmnd .= ' --no-close' unless not $args->{'no-close'} and not $args->{'noclose'};
    #  --screen-center | --under-mouse | --auto-placement
    $cmnd .= ' --screen-center' unless not $args->{'screen-center'} and not $args->{'screencenter'};
    $cmnd .= ' --under-mouse' unless not $args->{'under-mouse'} and not $args->{'undermouse'};
    $cmnd .= ' --auto-placement' unless not $args->{'auto-placement'} and not $args->{'autoplacement'};
    #  --center | --right | --left | --fill
    $cmnd .= ' --center' unless not $args->{'center'};
    $cmnd .= ' --right' unless not $args->{'right'};
    $cmnd .= ' --left' unless not $args->{'left'};
    $cmnd .= ' --fill' unless not $args->{'fill'};
    #  --no-wrap | --wrap
    $cmnd .= ' --no-wrap' unless not $args->{'no-wrap'} and not $args->{'nowrap'};
    $cmnd .= ' --wrap' unless not $args->{'wrap'};
    #  --cr-wrap | --no-cr-wrap
    $cmnd .= ' --crwrap' unless not $args->{'crwrap'};
    $cmnd .= ' --nocrwrap' unless not $args->{'nocrwrap'};
    #  --buttons-style default|icon|text
    $cmnd .= ' --buttons-style "' . ($args->{'buttonsstyle'}||$args->{'buttons-style'}) . '"' unless not $args->{'buttons-style'} and not $args->{'buttonsstyle'};
    #  --fixed-font (tailbox, textbox, and editbox)
    $cmnd .= ' --fixed-font' unless not $args->{'fixed-font'} and not $args->{'fixedfont'};
    #  --time-stamp | --date-stamp (logbox)
    $cmnd .= ' --time-stamp' unless not $args->{'time-stamp'} and not $args->{'timestamp'};
    $cmnd .= ' --date-stamp' unless not $args->{'date-stamp'} and not $args->{'datestamp'};
    #  --reverse (logbox)
    $cmnd .= ' --reverse' unless not $args->{'reverse'};
    #  --keep-colors (logbox)
    $cmnd .= ' --keep-colors' unless not $args->{'keep-colors'} and not $args->{'keep-colours'} and not $args->{'keepcolors'} and not $args->{'keepcolours'};
    #  --interval <timeout> (input(s) boxes, combo box, range(s) boxes, spin(s) boxes, list boxes, menu box, treeview, calendar, timebox)
    $cmnd .= ' --interval "' . $args->{'interval'} . '"' unless not $args->{'interval'};
    #  --no-tags (menubox, checklist and radiolist)
    $cmnd .= ' --no-tags' unless not $args->{'no-tags'} and not $args->{'notags'};
    #  --item-help (menubox, checklist, radiolist, buildlist and treeview)
    $cmnd .= ' --item-help' unless not $args->{'item-help'} and not $args->{'itemhelp'};
    #  --default-item <tag> (menubox)
    $cmnd .= ' --default-item "' . ($args->{'defaultitem'}||$args->{'default-item'}) . '"' unless not $args->{'default-item'} and not $args->{'defaultitem'};
    #  --icon <xpm filename> (textbox, editbox, tailbox, logbox, fselect and dselect)
    $cmnd .= ' --icon "' . $args->{'icon'} . '"' unless not $args->{'icon'};
    #  --no-ok (tailbox and logbox)
    $cmnd .= ' --no-ok' unless not $args->{'no-ok'} and not $args->{'nook'};
    #  --no-cancel (infobox, gauge and progress)
    $cmnd .= ' --no-cancel' unless not $args->{'no-cancel'} and not $args->{'nocancel'};
    #  --no-buttons (textbox, tailbox, logbox, infobox  fselect and dselect)
    $cmnd .= ' --no-buttons' unless not $args->{'no-buttons'} and not $args->{'nobuttons'};
    #  --default-no !(wizard)
    $cmnd .= ' --default-no' unless not $args->{'default-no'} and not $args->{'defaultno'};
    #  --wizard !(msgbox, infobox, gauge and progress)
    $cmnd .= ' --wizard' unless not $args->{'wizard'};
    #  --help <help> (infobox, gauge and progress)
    $cmnd .= ' --help "' . $args->{'help'} . '"' unless not $args->{'help'};
    #  --print <printer> (textbox, editbox and tailbox)
    $cmnd .= ' --print "' . $args->{'print'} . '"' unless not $args->{'print'};
    #  --check <label> !(infobox, gauge and progress)
    $cmnd .= ' --check "' . $args->{'check'}||$self->{'_opts'}->{'check'} . '"' unless not $args->{'check'};
    #  --ok-label <label> !(wizard)
    $cmnd .= ' --ok-label "' . ($args->{'oklabel'}||$args->{'ok-label'}) . '"' unless not $args->{'ok-label'} and not $args->{'oklabel'};
    #  --cancel-label <label> !(wizard)
    $cmnd .= ' --cancel-label "' . ($args->{'cancellabel'}||$args->{'cancel-label'}) . '"' unless not $args->{'cancel-label'} and not $args->{'cancellabel'};
    #  --beep | --beep-after (all)
    #    $cmnd .= ' --beep' unless not $args->{'beep'};
    #  --ignore-eof (infobox and gauge)
    $cmnd .= ' --ignore-eof' unless not $args->{'ignore-eof'} and not $args->{'ignoreeof'};
    #  --smooth (tailbox and logbox)
    $cmnd .= ' --smooth' unless not $args->{'smooth'};

    $cmnd .= " " . $final;
    return($cmnd);
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
    } elsif ($rv == 2) {
		return("HELP");
    } elsif ($rv == 3) {
		return("PREVIOUS");
    } elsif ($rv == 254) {
		return("ERROR");
    } elsif ($rv == 255) {
		return("ESC");
    } elsif (not $rv or $rv =~ /^null$/i) {
		return("OK");
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --separate-output --combobox",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    if ($args->{'list'}) {
		$args->{'list'} = [ $args->{'list'} ] unless ref($args->{'list'}) eq "ARRAY";
		foreach my $item (@{$args->{'list'}}) {
			$command .= ' "' . $item . '"';
		}
    } else {
		$args->{'items'} = [ $args->{'items'} ] unless ref($args->{'items'}) eq "ARRAY";
		foreach my $item (@{$args->{'items'}}) {
			$command .= ' "' . $item . '"';
		}
    }

    my ($rv,$selected) = $self->command_string($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --rangebox",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'min'}||'0') . '"';
    $command .= ' "' . ($args->{'max'}||'100') . '"';
    $command .= ' "' . ($args->{'def'}||'0') . '"';

    my ($rv,$selected) = $self->command_string($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --separate-output --2rangesbox",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'label1'}||' ') . '"';
    $command .= ' "' . ($args->{'min1'}||'0') . '"';
    $command .= ' "' . ($args->{'max1'}||'100') . '"';
    $command .= ' "' . ($args->{'def1'}||'0') . '"';
    $command .= ' "' . ($args->{'label2'}||' ') . '"';
    $command .= ' "' . ($args->{'min2'}||'0') . '"';
    $command .= ' "' . ($args->{'max2'}||'100') . '"';
    $command .= ' "' . ($args->{'def2'}||'0') . '"';

    my ($rv,$selected) = $self->command_array($command);

    $self->rv($rv||'null');
    $self->rs('null');
    $self->ra('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --separate-output --3rangesbox",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'label1'}||' ') . '"';
    $command .= ' "' . ($args->{'min1'}||'0') . '"';
    $command .= ' "' . ($args->{'max1'}||'100') . '"';
    $command .= ' "' . ($args->{'def1'}||'0') . '"';
    $command .= ' "' . ($args->{'label2'}||' ') . '"';
    $command .= ' "' . ($args->{'min2'}||'0') . '"';
    $command .= ' "' . ($args->{'max2'}||'100') . '"';
    $command .= ' "' . ($args->{'def2'}||'0') . '"';
    $command .= ' "' . ($args->{'label3'}||' ') . '"';
    $command .= ' "' . ($args->{'min3'}||'0') . '"';
    $command .= ' "' . ($args->{'max3'}||'100') . '"';
    $command .= ' "' . ($args->{'def3'}||'0') . '"';

    my ($rv,$selected) = $self->command_array($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --separate-output --spinbox",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'min1'}||'0') . '"';
    $command .= ' "' . ($args->{'max1'}||'100') . '"';
    $command .= ' "' . ($args->{'def1'}||'') . '"';
    $command .= ' "' . ($args->{'label1'}||'') . '"';

    my ($rv,$selected) = $self->command_string($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --separate-output --2spinsbox",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'min1'}||'0') . '"';
    $command .= ' "' . ($args->{'max1'}||'100') . '"';
    $command .= ' "' . ($args->{'def1'}||'') . '"';
    $command .= ' "' . ($args->{'label1'}||' ') . '"';
    $command .= ' "' . ($args->{'min2'}||'0') . '"';
    $command .= ' "' . ($args->{'max2'}||'100') . '"';
    $command .= ' "' . ($args->{'def2'}||' ') . '"';
    $command .= ' "' . ($args->{'label2'}||' ') . '"';

    my ($rv,$selected) = $self->command_array($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --separate-output --3spinsbox",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'min1'}||'0') . '"';
    $command .= ' "' . ($args->{'max1'}||'100') . '"';
    $command .= ' "' . ($args->{'def1'}||'') . '"';
    $command .= ' "' . ($args->{'label1'}||' ') . '"';
    $command .= ' "' . ($args->{'min2'}||'0') . '"';
    $command .= ' "' . ($args->{'max2'}||'100') . '"';
    $command .= ' "' . ($args->{'def2'}||' ') . '"';
    $command .= ' "' . ($args->{'label2'}||' ') . '"';
    $command .= ' "' . ($args->{'min3'}||'0') . '"';
    $command .= ' "' . ($args->{'max3'}||'100') . '"';
    $command .= ' "' . ($args->{'def3'}||' ') . '"';
    $command .= ' "' . ($args->{'label3'}||' ') . '"';

    my ($rv,$selected) = $self->command_array($command);

    $self->rv($rv||'null');
    $self->rs('null');
    $self->ra('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->{'buildlist'} ||= 'buildlist';

    my $command = $self->_mk_cmnd(" --separate-output --".$self->{'buildlist'},@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'menuheight'}||$args->{'listheight'}||'5') . '"';

    if ($args->{'list'}) {
		$args->{'list'} = [ ' ', [' ', 1] ] unless ref($args->{'list'}) eq "ARRAY";
		my ($item,$info);
		while (@{$args->{'list'}}) {
			$item = shift(@{$args->{'list'}});
			$info = shift(@{$args->{'list'}});
			$command .= ' "'.$item.'" "'.$info->[0].'" "'.(($info->[1]) ? 'on' : 'off').'"';
			$command .= ' "'.($info->[2]||' ').'"' unless not $args->{'itemhelp'};
		}
    } else {
		$args->{'items'} = [ ' ', ' ', 'off' ] unless ref($args->{'items'}) eq "ARRAY";
		foreach my $item (@{$args->{'items'}}) {
			$command .= ' "' . $item . '"';
		}
    }
    my ($rv,$selected) = $self->command_array($command);

    $self->rv($rv||'null');
    $self->rs('null');
    $self->ra('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->{'treeview'} ||= 'treeview';

    my $command = $self->_mk_cmnd(" --separate-output --".$self->{'treeview'},@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'menuheight'}||$args->{'listheight'}||'5') . '"';

    if ($args->{'list'}) {
		$args->{'list'} = [ ' ', [' ', 1, 1 ] ] unless ref($args->{'list'}) eq "ARRAY";
		my ($item,$info);
		while (@{$args->{'list'}}) {
			$item = shift(@{$args->{'list'}});
			$info = shift(@{$args->{'list'}});
			$command .= ' "'.$item.'" "'.$info->[0].'" "'.(($info->[1]) ? 'on' : 'off').'" "'.($info->[2]||1).'"';
			$command .= ' "'.($info->[3]||' ').'"' unless not $args->{'itemhelp'};
		}
    } else {
		$args->{'items'} = [ ' ', ' ', 'off' ] unless ref($args->{'items'}) eq "ARRAY";
		foreach my $item (@{$args->{'items'}}) {
			$command .= ' "' . $item . '"';
		}
    }
    my ($rv,$selected) = $self->command_string($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --separate-output --calendar",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'14') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'day'}||'1') . '"';
    $command .= ' "' . ($args->{'month'}||'1') . '"';
    $command .= ' "' . ($args->{'year'}||'1970') . '"';

    my ($rv,$selected) = $self->command_string($command);
    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --separate-output --timebox",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'14') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    my ($rv,$selected) = $self->command_string($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(' --yesno',@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    my $rv = $self->command_state($command);

    $self->rv($rv||'null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->ra("NO");
		$self->rs("NO");
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $val = $args->{'inputs'} || $args->{'password'} || 1;

    my $cmnd_prefix;
    if ($args->{'password'}) {
		if ($val == 3) {
			$cmnd_prefix = ' --separate-output --password --password --password --3inputsbox';
		} elsif ($val == 2) {
			$cmnd_prefix = ' --separate-output --password --password --2inputsbox';
		} else {
			$cmnd_prefix = ' --password --inputbox';
		}
    } else {
		if ($val == 3) {
			$cmnd_prefix = ' --separate-output --3inputsbox';
		} elsif ($val == 2) {
			$cmnd_prefix = ' --separate-output --2inputsbox';
		} else {
			$cmnd_prefix = ' --inputbox';
		}
    }

    my $command = $self->_mk_cmnd($cmnd_prefix,@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    $command .= ' "' . ($args->{'entry'}||$args->{'init'}||'') . '"' if $val == 1;

    $command .= ' "' . ($args->{'label1'}||' ') . '"' if $val > 1;
    $command .= ' "' . ($args->{'input1'}||'') . '"' if $val > 1;
    $command .= ' "' . ($args->{'label2'}||' ') . '"' if $val >= 2;
    $command .= ' "' . ($args->{'input2'}||'') . '"' if $val >= 2;
    $command .= ' "' . ($args->{'label3'}||' ') . '"' if $val >= 3;
    $command .= ' "' . ($args->{'input3'}||'') . '"' if $val >= 3;

    my ($rv,$text);
    if ($val == 1) {
		($rv,$text) = $self->command_string($command);
    } else {
		($rv,$text) = $self->command_array($command);
    }

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
		if ($val == 1) {
			$self->ra($text);
			$self->rs($text);
		} else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $args->{'msgbox'} ||= 'msgbox';

    my $command = $self->_mk_cmnd(' --'.$args->{'msgbox'},@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . (($args->{'wait'}) ? $args->{'wait'} * 1000 : ($args->{'timeout'}||'5000')) . '"'
     unless $args->{'msgbox'} ne 'infobox';

    my $rv = $self->command_state($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $args->{'textbox'} ||= 'textbox';

    my $command = $self->_mk_cmnd(" --".$args->{'textbox'},@_);
    $command .= ' "' . ($args->{'filename'}||$args->{'path'}||'.') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    my ($rv,$text) = $self->command_string($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --separate-output --menu",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'menuheight'}||$args->{'listheight'}||'5') . '"';

    if ($args->{'list'}) {
		$args->{'list'} = [ ' ', ' ' ] unless ref($args->{'list'}) eq "ARRAY";
		foreach my $item (@{$args->{'list'}}) {
			$command .= ' "' . $item . '"';
		}
    } else {
		$args->{'items'} = [ ' ', ' ' ] unless ref($args->{'items'}) eq "ARRAY";
		foreach my $item (@{$args->{'items'}}) {
			$command .= ' "' . $item . '"';
		}
    }

    my ($rv,$selected) = $self->command_string($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->{'checklist'} ||= 'checklist';

    my $command = $self->_mk_cmnd(" --separate-output --".$self->{'checklist'},@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'menuheight'}||$args->{'listheight'}||'5') . '"';

    if ($args->{'list'}) {
		$args->{'list'} = [ ' ', [' ', 1] ] unless ref($args->{'list'}) eq "ARRAY";
		my ($item,$info);
		while (@{$args->{'list'}}) {
			$item = shift(@{$args->{'list'}});
			$info = shift(@{$args->{'list'}});
			$command .= ' "'.$item.'" "'.$info->[0].'" "'.(($info->[1]) ? 'on' : 'off').'"';
			$command .= ' "'.($info->[2]||' ').'"' unless not $args->{'itemhelp'};
		}
    } else {
		$args->{'items'} = [ ' ', ' ', 'off' ] unless ref($args->{'items'}) eq "ARRAY";
		foreach my $item (@{$args->{'items'}}) {
			$command .= ' "' . $item . '"';
		}
    }
    my ($rv,$selected) = $self->command_array($command);

    $self->rv($rv||'null');
    $self->rs('null');
    $self->ra('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->{'radiolist'} ||= 'radiolist';

    my $command = $self->_mk_cmnd(" --separate-output --".$self->{'radiolist'},@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'menuheight'}||$args->{'listheight'}||'5') . '"';

    if ($args->{'list'}) {
		$args->{'list'} = [ ' ', [' ', 1] ] unless ref($args->{'list'}) eq "ARRAY";
		my ($item,$info);
		while (@{$args->{'list'}}) {
			$item = shift(@{$args->{'list'}});
			$info = shift(@{$args->{'list'}});
			$command .= ' "'.$item.'" "'.$info->[0].'" "'.(($info->[1]) ? 'on' : 'off').'"';
			$command .= ' "'.($info->[2]||' ').'"' unless not $args->{'itemhelp'};
		}
    } else {
		$args->{'items'} = [ ' ', ' ', 'off' ] unless ref($args->{'items'}) eq "ARRAY";
		foreach my $item (@{$args->{'items'}}) {
			$command .= ' "' . $item . '"';
		}
    }

    my ($rv,$selected) = $self->command_string($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --fselect",@_);
    my $path = $args->{'path'} || abs_path();
    $command .= ' "' . ((-d $path) ? $path . '/' : $path) . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    my ($rv,$file) = $self->command_string($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --dselect",@_);
    my $path = $args->{'path'} || abs_path();
    $command .= ' "' . ((-d $path) ? $path . '/' : $path) . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    my ($rv,$file) = $self->command_string($command);

    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
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
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->{'_PROGRESS'} ||= {};
    $self->{'_PROGRESS'}->{'ARGS'} = $args;

    if (defined $self->{'_PROGRESS'}->{'FH'}) {
		$self->rv(129);
		$self->_post($args);
		return(0);
    }

    my $command = $self->_mk_cmnd(" --progress",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'maxdots'}||'') . '"' unless not $args->{'maxdots'} and not $args->{'msglen'};
    $command .= ' "' . ($args->{'msglen'}||'') . '"' unless not $args->{'msglen'};
    $self->_debug("command: ".$command,2);

    $self->{'_PROGRESS'}->{'FH'} = new FileHandle;
    $self->{'_PROGRESS'}->{'FH'}->open("| $command");
    my $rv = $? >> 8;
    $self->{'_PROGRESS'}->{'FH'}->autoflush(1);
    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) { $this_rv = 0; }
    else { $this_rv = 1; }
    return($this_rv);
}
sub gauge_start {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->{'_GAUGE'} ||= {};
    $self->{'_GAUGE'}->{'ARGS'} = $args;

    if (defined $self->{'_GAUGE'}->{'FH'}) {
		$self->rv(129);
		$self->_post($args);
		return(0);
    }

    my $command = $self->_mk_cmnd(" --gauge",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'percentage'}||'0') . '"';
    $self->_debug("command: ".$command,2);

    $self->{'_GAUGE'}->{'FH'} = new FileHandle;
    $self->{'_GAUGE'}->{'FH'}->open("| $command");
    my $rv = $? >> 8;
    $self->{'_GAUGE'}->{'FH'}->autoflush(1);
    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) { $this_rv = 0; }
    else { $this_rv = 1; }
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
