package UI::Dialog::Backend::GDialog;
###############################################################################
#  Copyright (C) 2004  Kevin C. Krinke <kckrinke@opendoorsoftware.com>
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
use Carp;
use UI::Dialog::Backend;

BEGIN {
    use vars qw( $VERSION @ISA );
    @ISA = qw( UI::Dialog::Backend );
    $VERSION = '1.08';
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

	$self->{'_opts'}->{'literal'} = $cfg->{'literal'} || 0;
    $self->{'_opts'}->{'callbacks'} = $cfg->{'callbacks'} || undef();
    $self->{'_opts'}->{'debug'} = $cfg->{'debug'} || undef();
    $self->{'_opts'}->{'title'} = $cfg->{'title'} || undef();
    $self->{'_opts'}->{'backtitle'} = $cfg->{'backtitle'} || undef();
    $self->{'_opts'}->{'width'} = $cfg->{'width'} || 65;
    $self->{'_opts'}->{'height'} = $cfg->{'height'} || 10;
    $self->{'_opts'}->{'percentage'} = $cfg->{'percentage'} || 1;
    $self->{'_opts'}->{'bin'} ||= $self->_find_bin('gdialog.real') || $self->_find_bin('gdialog') || '/usr/bin/gdialog';
    $self->{'_opts'}->{'autoclear'} = $cfg->{'autoclear'} || 0;
    $self->{'_opts'}->{'clearbefore'} = $cfg->{'clearbefore'} || 0;
    $self->{'_opts'}->{'clearafter'} = $cfg->{'clearafter'} || 0;
    $self->{'_opts'}->{'beepbin'} = $cfg->{'beepbin'} || $self->_find_bin('beep') || '/usr/bin/beep';
    $self->{'_opts'}->{'beepbefore'} = $cfg->{'beepbefore'} || 0;
    $self->{'_opts'}->{'beepafter'} = $cfg->{'beepafter'} || 0;
    $self->{'_opts'}->{'timeout'} = $cfg->{'timeout'} || 0;
    $self->{'_opts'}->{'wait'} = $cfg->{'wait'} || 0;
    unless (-x $self->{'_opts'}->{'bin'}) {
		croak("the gdialog binary could not be found at: ".$self->{'_opts'}->{'bin'});
    }

    return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Private Methods
#:

my $SIG_CODE = {};
sub _del_gauge {
    my $CODE = $SIG_CODE->{$$};
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
    my $cmnd;
    my $args = $self->_merge_attrs(@_);

    $cmnd = $args->{'bin'};

    $cmnd .= ' --title "' . ($args->{'title'} || $args->{'title'}) . '"'
     unless not $args->{'title'} and not $args->{'title'};
    $cmnd .= ' --backtitle "' . ($args->{'backtitle'} || $args->{'backtitle'}) . '"'
     unless not $args->{'backtitle'} and not $args->{'backtitle'};
    $cmnd .= ' --separate-output' unless not $args->{'separate-output'} and not $args->{'separate-output'};

    $cmnd .= " " . $final;
    return($cmnd);
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public Methods
#:

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Ask a binary question (Yes/No)
sub yesno {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(' --yesno',@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    my $rv = $self->command_state($command);
    $self->rv($rv||'null');
    $self->ra('null');
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

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Text entry
sub inputbox {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(' --inputbox',@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'init'}||'') . '"'
     unless not $args->{'init'} and not $args->{'entry'};

    my ($rv,$text) = $self->command_string($command);
    $self->rv($rv||'null');
    $self->ra('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->rs('null');
		$this_rv = 0;
    } else {
		$self->ra($text);
		$self->rs($text);
		$this_rv = $text;
    }
    $self->_post($args);
    return($this_rv);
}
#: password boxes aren't supported by gdialog
sub password {
    my $self = shift();
    $self->msgbox(text=> 'GDialog does not support passwords at all, '.
				  'you will see the text as you type in the next dialog.' );
    return($self->inputbox('caller',((caller(1))[3]||'main'),@_));
}

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
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

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
sub infobox {
    my $self = shift();
    return($self->msgbox('caller',((caller(1))[3]||'main'),@_,'msgbox','infobox'));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: File box
sub textbox {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --textbox",@_);
    $command .= ' "' . ($args->{'path'}||'.') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    my ($rv,$text) = $self->command_string($command);
    $self->rv($rv||'null');
    $self->ra('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->rs('null');
		$this_rv = 0;
    } else {
		$self->ra($text);
		$self->rs($text);
		$this_rv = $text;
    }
    $self->_post($args);
    return($this_rv);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: a simple menu list
sub menu {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --menu",@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'}))||' ') . '"';
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
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->rs('null');
		$this_rv = 0;
    } else {
		$self->ra($selected);
		$self->rs($selected);
		$this_rv = $selected;
    }
    $self->_post($args);
    return($this_rv);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: a check list
sub checklist {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->{'checklist'} ||= 'checklist';

    my $command = $self->_mk_cmnd(" --".$self->{'checklist'},@_,'separate-output',1);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'menuheight'}||$args->{'listheight'}||'5') . '"';

    if ($args->{'list'}) {
		$args->{'list'} = [ ' ', [' ', 0] ] unless ref($args->{'list'}) eq "ARRAY";
		my ($item,$info);
		while (@{$args->{'list'}}) {
			$item = shift(@{$args->{'list'}});
			$info = shift(@{$args->{'list'}});
			$command .= ' "'.$item.'" "'.$info->[0].'" "'.(($info->[1]) ? 'on' : 'off').'"';
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
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->ra('null');
		$this_rv = 0;
    } else {
		$self->rs(join("\n",@$selected));
		$self->ra(@$selected);
		$this_rv = $selected;
    }
    $self->_post($args);
    return($this_rv) unless ref($this_rv) eq "ARRAY";
    return(@{$this_rv});
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: a radio button list
sub radiolist {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->{'radiolist'} ||= 'radiolist';

    my $command = $self->_mk_cmnd(" --".$self->{'radiolist'},@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'menuheight'}||$args->{'listheight'}||'5') . '"';

    if ($args->{'list'}) {
		$args->{'list'} = [ ' ', [' ', 0] ] unless ref($args->{'list'}) eq "ARRAY";
		my ($item,$info);
		while (@{$args->{'list'}}) {
			$item = shift(@{$args->{'list'}});
			$info = shift(@{$args->{'list'}});
			$command .= ' "'.$item.'" "'.$info->[0].'" "'.(($info->[1]) ? 'on' : 'off').'"';
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
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->rs('null');
		$this_rv = 0;
    } else {
		$self->ra($selected);
		$self->rs($selected);
		$this_rv = $selected;
    }
    $self->_post($args);
    return($this_rv);
}

# #:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# #: progress meter
# sub gauge_start {
#     my $self = shift();
#     my $args = $self->_merge_attrs(@_);

#     return(0) unless not defined $self->{'_GAUGE'};
#     $self->_beep($args->{'beepbefore'});

#     my $command = $self->_mk_cmnd(" --gauge",@_);
#    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'}))||' ') . '"';
#     $command .= ' "' . ($args->{'height'}||'20') . '"';
#     $command .= ' "' . ($args->{'width'}||'65') . '"';
#     $command .= ' "' . ($args->{'percentage'}||'0') . '"';

#     $self->{'_GAUGE'} = new FileHandle;
#     $self->{'_GAUGE'}->open("| $command");
#     my $rv = $? >> 8;
#     $self->{'_GAUGE'}->autoflush(1);
#     $self->ra('null');
#     $self->rs('null');
#     if ($rv && $rv >= 1) {
# 	return(0);
#     } else {
# 	return(1);
#     }
# }
# sub gauge_inc {
#     my $self = $_[0];
#     my $incr = $_[1] || 1;

#     return(0) unless defined $self->{'_GAUGE'};

#     my $fh = $self->{'_GAUGE'};
#     $self->{'_GAUGE_PERCENT'} += $incr;
#     $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
#     unless ($self->{'_GAUGE_PERCENT'} < 100) {
# 	$self->gauge_end();
# 	return(1);
#     }
#     print $fh $self->{'_GAUGE_PERCENT'}."\n";
#     return(((defined $self->{'_GAUGE'}) ? 1 : 0));
# }
# sub gauge_dec {
#     my $self = $_[0];
#     my $decr = $_[1] || 1;

#     return(0) unless defined $self->{'_GAUGE'};

#     my $fh = $self->{'_GAUGE'};
#     $self->{'_GAUGE_PERCENT'} -= $decr;
#     $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
#     unless ($self->{'_GAUGE_PERCENT'} < 100) {
# 	$self->gauge_end();
# 	return(1);
#     }
#     print $fh $self->{'_GAUGE_PERCENT'}."\n";
#     return(((defined $self->{'_GAUGE'}) ? 1 : 0));
# }
# sub gauge_set {
#     my $self = $_[0];
#     my $perc = $_[1] || $self->{'_GAUGE_PERCENT'} || 1;

#     my $fh = $self->{'_GAUGE'};
#     return(0) unless $self->{'_GAUGE'};

#     $self->{'_GAUGE_PERCENT'} = $perc;
#     unless ($self->{'_GAUGE_PERCENT'} < 100) {
# 	$self->gauge_end();
# 	return(1);
#     }
#     $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
#     print $fh $self->{'_GAUGE_PERCENT'}."\n";
#     return(((defined $self->{'_GAUGE'}) ? 1 : 0));
# }
# sub gauge_text {
#     my $self = $_[0];
#     my $mesg = $_[1] || return(0);

#     my $fh = $self->{'_GAUGE'};
#     return(0) unless $self->{'_GAUGE'};

#     $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
#     print $fh "\nXXX\n\n".$mesg."\n\nXXX\n\n".$self->{'_GAUGE_PERCENT'}."\n";
#     return(((defined $self->{'_GAUGE'}) ? 1 : 0));
# }
# sub gauge_end {
#     my $self = $_[0];

#     my $fh = $self->{'_GAUGE'};
#     return(0) unless $self->{'_GAUGE'};

#     $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
#     $self->{'_GAUGE'}->close();
#     delete($self->{'_GAUGE'});
#     delete($self->{'_GAUGE_PERCENT'});
#     $self->_beep();
#     $self->ra('null');
#     $self->rs('null');
#     return(1);
# }


1;

