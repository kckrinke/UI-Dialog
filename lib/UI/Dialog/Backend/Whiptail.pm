package UI::Dialog::Backend::Whiptail;
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
use Time::HiRes qw( sleep );
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
    $self->{'_opts'}->{'listheight'} = $cfg->{'listheight'} || $cfg->{'menuheight'} || 10;
    $self->{'_opts'}->{'percentage'} = $cfg->{'percentage'} || 1;
    $self->{'_opts'}->{'bin'} ||= $self->_find_bin('whiptail');
    $self->{'_opts'}->{'autoclear'} = $cfg->{'autoclear'} || 0;
    $self->{'_opts'}->{'clearbefore'} = $cfg->{'clearbefore'} || 0;
    $self->{'_opts'}->{'clearafter'} = $cfg->{'clearafter'} || 0;
    $self->{'_opts'}->{'beepbin'} = $cfg->{'beepbin'} || $self->_find_bin('beep') || '/usr/bin/beep';
    $self->{'_opts'}->{'beepbefore'} = $cfg->{'beepbefore'} || 0;
    $self->{'_opts'}->{'beepafter'} = $cfg->{'beepafter'} || 0;
    $self->{'_opts'}->{'timeout'} = $cfg->{'timeout'} || 0;
    $self->{'_opts'}->{'wait'} = $cfg->{'wait'} || 0;
    unless (-x $self->{'_opts'}->{'bin'}) {
		croak("the whiptail binary could not be found at: ".$self->{'_opts'}->{'bin'});
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
    my $cmnd = $self->{'_opts'}->{'bin'};
    my $args = $self->_merge_attrs(@_);

    $cmnd .= ' --title "' . ($args->{'title'} || ' ') . '"' unless not $args->{'title'};
    $cmnd .= ' --backtitle "' . ($args->{'backtitle'} || ' ') . '"' unless not $args->{'backtitle'};
    $cmnd .= ' --separate-output' unless not $args->{'separate-output'};

    $cmnd .= " " . $final;
    return($cmnd);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Override Inherited Methods
#:
sub command_state {
    my $self = $_[0];
    my $cmnd = $_[1];
    $self->_debug("".$cmnd);
    system($cmnd . " 2> /dev/null");
    return($? >> 8);
}
sub command_string {
    my $self = $_[0];
    my $cmnd = $_[1];
    $self->_debug($cmnd);
    $self->gen_tempfile_name(); # don't accept the first result
    my $tmpfile = $self->gen_tempfile_name();
    my $text;
    system($cmnd." 2> ".$tmpfile);
    my $rv = $? >> 8;
    if (-f $tmpfile             # don't assume the file exists
		&& open(WHIPF,"<".$tmpfile)) {
		local $/;
		$text = <WHIPF>;
		close(WHIPF);
		unlink($tmpfile);
    } else { $text = ""; }
    return($text) unless defined wantarray;
    return (wantarray) ? ($rv,$text) : $text;
}
sub command_array {
    my $self = $_[0];
    my $cmnd = $_[1];
    $self->_debug($cmnd);
    $self->gen_tempfile_name(); # don't accept the first result
    my $tmpfile = $self->gen_tempfile_name();
    my $text;
    system($cmnd." 2> ".$tmpfile);
    my $rv = $? >> 8;
    if (-f $tmpfile             # don't assume the file exists
		&& open(WHIPF,"<".$tmpfile)) {
		local $/;
		$text = <WHIPF>;
		close(WHIPF);
		unlink($tmpfile);
    } else { $text = ""; }
    return([split("\n",$text)]) unless defined wantarray;
    return (wantarray) ? ($rv,[split("\n",$text)]) : [split("\n",$text)];
}

#: indent and organize the text argument
sub _organize_text {
    my $self = $_[0];
    my $text = $_[1] || return();
    my $width = $_[2] || 65;
	$width -= 4;                # take account of borders
    my @array;

    if (ref($text) eq "ARRAY") { push(@array,@{$text}); }
    elsif ($text =~ /\\n/) { @array = split(/\\n/,$text); }
    else { @array = split(/\n/,$text); }
    $text = undef();

    @array = $self->word_wrap($width,"","",@array);
    my $max = @array;
    for (my $i = 0; $i < $max; $i++) { $array[$i] = $self->_esc_text($array[$i]); }

    if ($self->{'scale'}) {
		foreach my $line (@array) {
			my $s_line = $self->__TRANSLATE_CLEAN($line);
			$s_line =~ s!\[A\=\w+\]!!gi;
			$self->{'width'} = length($s_line) + 5
			 if ($self->{'width'} - 5) < length($s_line)
			  && (length($s_line) <= $self->{'max-scale'});
		}
    }
    foreach my $line (@array) {
		my $pad;
		my $s_line = $self->_strip_text($line);
		if ($line =~ /\[A\=(\w+)\]/i) {
			my $align = $1;
			$line =~ s!\[A\=\w+\]!!gi;
			if (uc($align) eq "CENTER" || uc($align) eq "C") {
				$pad = ((($self->{'_opts'}->{'width'} - 5) - length($s_line)) / 2);
			} elsif (uc($align) eq "LEFT" || uc($align) eq "L") {
				$pad = 0;
			} elsif (uc($align) eq "RIGHT" || uc($align) eq "R") {
				$pad = (($self->{'_opts'}->{'width'} - 5) - length($s_line));
			}
		}
		if ($pad) { $text .= (" " x $pad).$line."\n"; }
		else { $text .= $line."\n"; }
    }
    $text = $self->_strip_text($text);
    chomp($text);
    return($text);
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
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    my $rv = $self->command_state($command);
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->ra("NO");
		$self->rs("NO");
		$self->rv($rv);
		$this_rv = 0;
    } else {
		$self->ra("YES");
		$self->rs("YES");
		$self->rv('null');
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

    my $cmnd_prefix = ' --inputbox';
    if ($args->{'password'}) { $cmnd_prefix = ' --passwordbox'; }
    my $command = $self->_mk_cmnd($cmnd_prefix,@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';
    $command .= ' "' . ($args->{'init'}||$args->{'entry'}||'') . '"'
     unless not $args->{'init'} and not $args->{'entry'};

    my ($rv,$text) = $self->command_string($command);
    $self->ra('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->rv($rv);
		$self->rs('null');
		$this_rv = 0;
    } else {
		$self->rv('null');
		$self->rs($text);
		$self->ra($text);
		$this_rv = $text;
    }
    $self->_post($args);
    return($this_rv);
}
#: password boxes aren't supported by gdialog
sub password {
    my $self = shift();
    return($self->inputbox('caller',((caller(1))[3]||'main'),@_,'password',1));
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

    my $command = $self->_mk_cmnd(' --scrolltext --'.$args->{'msgbox'},@_);
    $command .= ' "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    my $rv = $self->command_state($command);
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->rv($rv);
        $this_rv = 0;
    } else {
		if (($args->{'msgbox'} eq "infobox") && ($args->{'timeout'} || $args->{'wait'})) {
			my $s = int(($args->{'wait'}) ? $args->{'wait'} :
						($args->{'timeout'}) ? ($args->{'timeout'} / 1000.0) : 1.0);
			sleep($s);
		}
		$self->rv('null');
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

    my $command = $self->_mk_cmnd(" --scrolltext --textbox",@_);
    $command .= ' "' . ($args->{'path'}||'.') . '"';
    $command .= ' "' . ($args->{'height'}||'20') . '"';
    $command .= ' "' . ($args->{'width'}||'65') . '"';

    my ($rv,$text) = $self->command_string($command);
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->rv($rv);
		$this_rv = 0;
    } else {
		$self->rv('null');
		$this_rv = 1;
    }
    $self->_post($args);
    return($this_rv);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Lists
sub menu {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --menu",@_);
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
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->rv($rv);
		$self->rs('null');
		$self->ra('null');
		$this_rv = 0;
    } else {
		$self->rv('null');
		$self->rs($selected);
		$self->ra($selected);
		$this_rv = $selected;
    }
}
sub checklist {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->{'checklist'} ||= 'checklist';

    my $command = $self->_mk_cmnd(" --".$self->{'checklist'},@_,'separate-output',1);
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
		}
    } else {
		$args->{'items'} = [ ' ', ' ', 'off' ] unless ref($args->{'items'}) eq "ARRAY";
		foreach my $item (@{$args->{'items'}}) {
			$command .= ' "' . $item . '"';
		}
    }
    my ($rv,$selected) = $self->command_array($command);
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->rv($rv);
		$self->ra('null');
		$self->rs('null');
		$this_rv = 0;
    } else {
		$self->rv('null');
		$self->ra(@$selected);
		$self->rs(join("\n",@$selected));
		$this_rv = $selected;
    }
    $self->_post($args);
    return($this_rv) unless ref($this_rv) eq "ARRAY";
    return(@{$this_rv});
}
sub radiolist {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->{'radiolist'} ||= 'radiolist';

    my $command = $self->_mk_cmnd(" --".$self->{'radiolist'},@_);
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
		}
    } else {
		$args->{'items'} = [ ' ', ' ', 'off' ] unless ref($args->{'items'}) eq "ARRAY";
		foreach my $item (@{$args->{'items'}}) {
			$command .= ' "' . $item . '"';
		}
    }

    my ($rv,$selected) = $self->command_string($command);
    my $this_rv;
    if ($rv && $rv >= 1) {
		$self->rv($rv);
		$self->rs('null');
		$self->ra('null');
        $this_rv = 0;
    } else {
		$self->rv('null');
		$self->rs($selected);
		$self->ra($selected);
		$this_rv = $selected;
    }
    $self->_post($args);
    return($this_rv);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: progress meter
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
sub gauge_inc {
    my $self = $_[0];
    my $incr = $_[1] || 1;

    return(0) unless defined $self->{'_GAUGE'}->{'FH'};

    my $fh = $self->{'_GAUGE'}->{'FH'};
    $self->{'_GAUGE'}->{'PERCENT'} += $incr;
    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
    print $fh $self->{'_GAUGE'}->{'PERCENT'}."\n";
    return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub gauge_dec {
    my $self = $_[0];
    my $decr = $_[1] || 1;

    return(0) unless defined $self->{'_GAUGE'}->{'FH'};

    my $fh = $self->{'_GAUGE'}->{'FH'};
    $self->{'_GAUGE'}->{'PERCENT'} -= $decr;
    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
    print $fh $self->{'_GAUGE'}->{'PERCENT'}."\n";
    return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub gauge_set {
    my $self = $_[0];
    my $perc = $_[1] || $self->{'_GAUGE'}->{'PERCENT'} || 1;

    my $fh = $self->{'_GAUGE'}->{'FH'};
    return(0) unless $self->{'_GAUGE'}->{'FH'};

    $self->{'_GAUGE'}->{'PERCENT'} = $perc;
    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
    print $fh $self->{'_GAUGE'}->{'PERCENT'}."\n";
    return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub gauge_text {
    my $self = $_[0];
    my $mesg = $_[1] || return(0);

    my $fh = $self->{'_GAUGE'}->{'FH'};
    return(0) unless $self->{'_GAUGE'}->{'FH'};

    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
    print $fh "\nXXX\n\n".$mesg."\n\nXXX\n\n".$self->{'_GAUGE'}->{'PERCENT'}."\n";
    return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub gauge_stop {
    my $self = $_[0];

    return(0) unless $self->{'_GAUGE'}->{'FH'};

    my $args = $self->{'_GAUGE'}->{'ARGS'};
    my $fh = $self->{'_GAUGE'}->{'FH'};
    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
    $self->{'_GAUGE'}->{'FH'}->close();
    delete($self->{'_GAUGE'}->{'FH'});
    delete($self->{'_GAUGE'}->{'ARGS'});
    delete($self->{'_GAUGE'}->{'PERCENT'});
    delete($self->{'_GAUGE'});
    $self->rv('null');
    $self->rs('null');
    $self->ra('null');
    $self->_post($args);
    return(1);
}


1;
