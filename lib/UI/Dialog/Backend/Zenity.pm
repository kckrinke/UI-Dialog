package UI::Dialog::Backend::Zenity;
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
use Cwd qw( abs_path );
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
    $self->{'_opts'}->{'debug'} = $cfg->{'debug'} || undef();
    $self->{'_opts'}->{'window-icon'} = $cfg->{'window-icon'} || undef();
    $self->{'_opts'}->{'title'} = $cfg->{'title'} || undef();
    $self->{'_opts'}->{'width'} = $cfg->{'width'} || 65;
    $self->{'_opts'}->{'height'} = $cfg->{'height'} || 10;
    $self->{'_opts'}->{'display'} = $cfg->{'display'} || undef();
    $self->{'_opts'}->{'name'} = $cfg->{'name'} || undef();
    $self->{'_opts'}->{'class'} = $cfg->{'class'} || undef();
    $self->{'_opts'}->{'bin'} = $self->_find_bin('zenity');
    $self->{'_opts'}->{'autoclear'} = $cfg->{'autoclear'} || 0;
    $self->{'_opts'}->{'clearbefore'} = $cfg->{'clearbefore'} || 0;
    $self->{'_opts'}->{'clearafter'} = $cfg->{'clearafter'} || 0;
    $self->{'_opts'}->{'beepbin'} = $cfg->{'beepbin'} || $self->_find_bin('beep') || '/usr/bin/beep';
    $self->{'_opts'}->{'beepbefore'} = $cfg->{'beepbefore'} || 0;
    $self->{'_opts'}->{'beepafter'} = $cfg->{'beepafter'} || 0;
    $self->{'_opts'}->{'callbacks'} = $cfg->{'callbacks'} || undef();
    $self->{'_opts'}->{'timeout'} = $cfg->{'timeout'} || 0;
    $self->{'_opts'}->{'wait'} = $cfg->{'wait'} || 0;
    unless (-x $self->{'_opts'}->{'bin'}) {
		croak("the zenity binary could not be found at: ".$self->{'_opts'}->{'bin'});
    }

    my $command = $self->{'_opts'}->{'bin'}." --version";
    my $version = `$command 2>&1`;
    chomp( $version );
    $self->{'ZENITY_VERSION'} = $version || '1';

    return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Private Methods
#:

my $SIG_CODE = {};
sub _del_gauge {
    #: this is beyond self...
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
    my $cmnd = shift();
    my $args = shift();

    $ENV{'ZENITY_CANCEL'} = '1';
    $ENV{'ZENITY_ERROR'}  = '254';
    $ENV{'ZENITY_ESC'}    = '255';
    $ENV{'ZENITY_EXTRA'}  = '3';
    $ENV{'ZENITY_HELP'}   = '2';
    $ENV{'ZENITY_OK'}     = '0';

    $cmnd = $self->{'_opts'}->{'bin'} . " " . $cmnd;

    $cmnd .= ' --title "' . $args->{'title'} . '"' unless not $args->{'title'};
    $cmnd .= ' --window-icon "' . $args->{'window-icon'} . '"' unless not $args->{'window-icon'};
    $cmnd .= ' --width "' . $args->{'width'} . '"' unless not $args->{'width'};
    $cmnd .= ' --height "' . $args->{'height'} . '"' unless not $args->{'height'};
    $cmnd .= ' --display "'.$args->{'display'} . '"' unless not $args->{'display'};
    $cmnd .= ' --name "'.$args->{'name'} . '"' unless not $args->{'name'};
    $cmnd .= ' --class "'.$args->{'class'} . '"' unless not $args->{'class'};

    return($cmnd);
}
sub _is_bad_version {
    my $self = shift();
    my ($d_maj, $d_min, $d_mac) = ( 1, 4, 0 );
    my ($z_maj, $z_min, $z_mac) = ( 0, 0, 0 );
    my $zenity_version = $self->{'ZENITY_VERSION'} || '0.0.0';
    if ( $zenity_version =~ m!^(\d+)\.(\d+)\.(\d+)$! ) {
        ($z_maj, $z_min, $z_mac) = ( $1, $2, $3 );
    }
    if ( ( $d_maj <  $z_maj                                        ) ||
         ( $d_maj == $z_maj && $d_min <  $z_min                    ) ||
         ( $d_maj == $z_maj && $d_min == $z_min && $d_mac < $z_mac )
       ) {
        return(0);
    }
    return(1);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Override Inherited Methods
#:

#: execute a simple command (return the exit code only);
sub command_state {
    my $self = $_[0];
    my $cmnd = $_[1];
    $self->_debug("command: ".$cmnd,1);
    system($cmnd . "> /dev/null 2> /dev/null");
    my $rv = $? >> 8;
    $self->_debug("command rv: ".$rv,2);
    return($rv);
}

#: execute a command and return the exit code and one-line SCALAR
sub command_string {
    my $self = $_[0];
    my $cmnd = $_[1];
    $self->_debug("command: ".$cmnd,1);
    my $text;
    if ($self->_is_bad_version()) {
		#we should ignore STDERR...
		chomp($text = `$cmnd`);
    } else {
		chomp($text = `$cmnd 2>&1`);
    }
    my $rv = $? >> 8;
    $self->_debug("command rs: ".$rv." '".$text."'",2);
    return($text) unless defined wantarray;
    return (wantarray) ? ($rv,$text) : $text;
}

#: execute a command and return the exit code and ARRAY of data
sub command_array {
    my $self = $_[0];
    my $cmnd = $_[1];
    $self->_debug("command: ".$cmnd,1);
    my $text;
    if ($self->_is_bad_version()) {
		#we should ignore STDERR...
		chomp($text = `$cmnd`);
    } else {
		chomp($text = `$cmnd 2>&1`);
    }
    my $rv = $? >> 8;
    $self->_debug("command ra: ".$rv." '".$text."'",2);
    return([split(/\n/,$text)]) unless defined wantarray;
    return (wantarray) ? ($rv,[split(/\n/,$text)]) : [split(/\n/,$text)];
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public Methods
#:

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Ask a binary question (Yes/No)
sub question {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --question",$args);
    $command .= ' --text "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"' unless not $args->{'text'};


    my $rv = $self->command_state($command);
    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
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
#: Zenity doesn't support alternation of the buttons like gdialog et al.
#: so here we just wrap for compliance.
sub yesno {
    my $self = shift();
    return($self->question('caller',((caller(1))[3]||'main'),@_));
}
sub noyes {
    my $self = shift();
    return($self->question('caller',((caller(1))[3]||'main'),@_));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Text entry
sub entry {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --entry",$args);
    $command .= ' --text "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"' unless not $args->{'text'};
    $command .= ' --hide-text' unless not $args->{'hide-text'};
    $command .= ' --entry-text "' . ($args->{'entry'}||$args->{'init'}) . '"'
     unless not $args->{'entry'} and not $args->{'init'};

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
sub inputbox {
    my $self = shift();
    return($self->entry('caller',((caller(1))[3]||'main'),@_));
}
sub password {
    my $self = shift();
    return($self->entry('caller',((caller(1))[3]||'main'),@_,'hide-text',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Text box
sub info {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd((($args->{'error'}) ? " --error" :
								   ($args->{'warning'}) ? " --warning" : " --info"),$args);
    $command .= ' --text "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"' unless not $args->{'text'};

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
sub msgbox {
    my $self = shift();
    return($self->info('caller',((caller(1))[3]||'main'),@_));
}
sub error {
    my $self = shift();
    return($self->info('caller',((caller(1))[3]||'main'),@_,'error',1));
}
sub warning {
    my $self = shift();
    return($self->info('caller',((caller(1))[3]||'main'),@_,'warning',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: File box
sub text_info {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --text-info",$args);
    $command .= ' --editable' unless not $args->{'editable'};
    $command .= ' --filename "' . ($args->{'path'}||$args->{'filename'}) . '"'
     unless not $args->{'filename'} and not $args->{'path'};

    my ($rv,$text) = $self->command_string($command);
    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv = 0;
    if ($rv && $rv >= 1) {
		$self->rs('null');
    } elsif ($args->{'editable'}) {
		$self->ra($text);
		$self->rs($text);
		$this_rv = $text;
    } else {
		$this_rv = 1;
    }
    $self->_post($args);
    return($this_rv);
}
sub textbox {
    my $self = shift();
    return($self->text_info('caller',((caller(1))[3]||'main'),@_));
}
sub editbox {
    my $self = shift();
    return($self->text_info('caller',((caller(1))[3]||'main'),@_,'editable',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Lists
sub list {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --list",$args);
    $command .= ($args->{'checklist'}) ? ' --checklist' : ($args->{'radiolist'}) ? ' --radiolist' : "";
    $command .= ' --separator "\n"';
    #: not quite sure how to implement the editability...
    #    $command .= ' --editable' unless not $args->{'editable'};
    #: --text is not implemented for list widgets, yet...
    #    $command .= ' --text "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"' unless not $args->{'text'};

    if ($args->{'list'} && ($args->{'checklist'} || $args->{'radiolist'})) {
		if ($args->{'checklist'} || $args->{'radiolist'}) {
			$command .= " --column ' ' --column ' ' --column ' '";
		} else {
			$command .= " --column ' ' --column ' '";
		}
		$args->{'list'} = [ ' ', [' ', 1] ] unless ref($args->{'list'}) eq "ARRAY";
		my ($item,$info);
		while (@{$args->{'list'}}) {
			$item = shift(@{$args->{'list'}});
			$info = shift(@{$args->{'list'}});
			if (ref($info) eq "ARRAY") {
				$command .= ' "'.(($info->[1]) ? 'TRUE' : 'FALSE').'" "'.$item.'" "'.$info->[0].'"';
			} else {
				$command .= ' "'.$item.'" "'.$info.'"';
			}
		}
    } else {
		$args->{'columns'} = [ ' ', ' ' ] unless ref($args->{'columns'}) eq "ARRAY";
		foreach my $column (@{$args->{'columns'}}) {
			$command .= ' --column "' . $column . '"';
		}
		$args->{'items'} = $args->{'list'} unless not $args->{'list'};
		$args->{'items'} = [ ' ',' ' ] unless ref($args->{'columns'}) eq "ARRAY";
		foreach my $item (@{$args->{'items'}}) {
			$command .= ' "' . $item . '"';
		}
    }

    my ($rv,$selected) = $self->command_array($command);
    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    if ($rv && $rv >= 1) {
		$self->_post($args);
		return(0);
    } else {
		if ($args->{'checklist'}) {
			$self->ra(@$selected);
			$self->rs(join("\n",@$selected));
			$self->_post($args);
			return(@{$selected});
		} else {
			$self->ra($selected->[0]);
			$self->rs($selected->[0]);
			$self->_post($args);
			return($selected->[0]);
		}
    }
}
sub menu {
    my $self = shift();
    return($self->list('caller',((caller(1))[3]||'main'),@_));
}
sub checklist {
    my $self = shift();
    return($self->list('caller',((caller(1))[3]||'main'),@_,'checklist',1));
}
sub radiolist {
    my $self = shift();
    return($self->list('caller',((caller(1))[3]||'main'),@_,'radiolist',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: file select
sub fselect {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $args->{'path'} = (-d $args->{'path'}) ? $args->{'path'}."/" : $args->{'path'};
    $args->{'path'} =~ s!/+!/!g;

    my $command = $self->_mk_cmnd(" --file-selection",$args);
    $command .= ' --filename "' . ($args->{'path'}||abs_path()) . '"';

    $self->_debug("fselect: ".$args->{'path'});
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

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: calendar
sub calendar {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    my $command = $self->_mk_cmnd(" --calendar",$args);
    $command .= ' --text "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"' unless not $args->{'text'};
    $command .= ' --date-format "' . ($args->{'date-format'}||'%d/%m/%y') . '"';
    $command .= ' --day "' . $args->{'day'} . '"' unless not $args->{'day'};
    $command .= ' --month "' . $args->{'month'} . '"' unless not $args->{'month'};
    $command .= ' --year "' . $args->{'year'} . '"' unless not $args->{'year'};

    my ($rv,$date) = $self->command_string($command);
    $self->rv($rv||'null');
    $self->ra('null');
    $self->rs('null');
    my $this_rv;
    if ($rv && $rv >= 1) {
		$this_rv = 0;
    } else {
		chomp($date);
		# the end programmer can alter the date format
		$self->ra(split(/\//,$date)) if $date =~ /^\d+\/\d+\/\d+$/;
		$self->rs($date);
		$this_rv = $date;
    }
    $self->_post($args);
    return($this_rv);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: progress

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

    my $command = $self->_mk_cmnd(" --progress",$args);
    $command .= ' --text "' . (($args->{'literal'} ? $args->{'text'} : $self->_organize_text($args->{'text'},$args->{'width'}))||' ') . '"' unless not $args->{'text'};
    $command .= ' --percentage "' . ($args->{'percentage'}||'0') . '"';
    $command .= ' --pulsate' unless not $args->{'pulsate'};

    $self->{'_GAUGE'}->{'FH'} = new FileHandle;
    $self->{'_GAUGE'}->{'FH'}->open("| $command");
    my $rv = ($? >> 8);
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

    return(0) unless $self->{'_GAUGE'}->{'FH'};

    my $fh = $self->{'_GAUGE'}->{'FH'};
    $self->{'_GAUGE'}->{'PERCENT'} = $perc;
    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
    print $fh $self->{'_GAUGE'}->{'PERCENT'}."\n";
    return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
#: Textual updates are not supported by Zenity...
sub gauge_text {
    my $self = $_[0];
    my $mesg = $_[1] || return(0);

    my $fh = $self->{'_GAUGE'};
    return(0) unless $self->{'_GAUGE'};

	#    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
	#    print $fh "\nXXX\n\n".$mesg."\n\nXXX\n\n".$self->{'_GAUGE'}->{'PERCENT'}."\n";
    return(((defined $self->{'_GAUGE'}) ? 1 : 0));
}
sub gauge_stop {
    my $self = $_[0];
    my $args = $self->{'_GUAGE'}->{'ARGS'} ||
     $self->_merge_attrs( title => 'gauge_stop',
						  'caller' => ((caller(1))[3]||'main') );

    unless ($self->{'_GAUGE'}->{'FH'}) {
		$self->rv(129);
		$self->_post($args);
		return(0);
    }

    my $fh = $self->{'_GAUGE'}->{'FH'};
    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
    $self->{'_GAUGE'}->{'FH'}->close();
    delete($self->{'_GAUGE'}->{'ARGS'});
    delete($self->{'_GAUGE'}->{'FH'});
    delete($self->{'_GAUGE'}->{'PERCENT'});
    delete($self->{'_GAUGE'});
    $self->rv('null');
    $self->rs('null');
    $self->ra('null');
    $self->_post($args);
    return(1);
}

1;

