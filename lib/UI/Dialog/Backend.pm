package UI::Dialog::Backend;
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
use Carp;
use Cwd qw( abs_path );
use File::Basename;
use Text::Wrap qw( wrap );

BEGIN {
    use vars qw($VERSION);
    $VERSION = '1.08';
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Constructor Method
#:

#: not even really necessary as this class is inherited, and the constructor is
#: more often than not overridden by the backend inheriting it.
sub new {
    my $proto = shift();
    my $class = ref($proto) || $proto;
    my $cfg = ((ref($_[0]) eq "HASH") ? $_[0] : (@_) ? { @_ } : {});
    my $self = { '_opts' => $cfg };
    bless($self, $class);
    return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Accessory Methods
#:

#: Provide the API interface to nautilus
sub nautilus {
    my $self = $_[0];
    my $nautilus = $self->{'_nautilus'} || {};
    unless (ref($nautilus) eq "UI::Dialog::Backend::Nautilus") {
		if ($self->_find_bin('nautilus')) {
			if (eval "require UI::Dialog::Backend::Nautilus; 1") {
				require UI::Dialog::Backend::Nautilus;
				$self->{'_nautilus'} = new UI::Dialog::Backend::Nautilus;
			}
		}
    }
    return($self->{'_nautilus'});
}

#: Provide the API interface to osd_cat (aka: xosd)
sub xosd {
    my $self = shift();
    my @args = (@_ %2 == 0) ? (@_) : ();
    my $xosd = $self->{'_xosd'} || {};
    unless (ref($xosd) eq "UI::Dialog::Backend::XOSD") {
		if ($self->_find_bin('osd_cat')) {
			if (eval "require UI::Dialog::Backend::XOSD; 1") {
				require UI::Dialog::Backend::XOSD;
				$self->{'_xosd'} = new UI::Dialog::Backend::XOSD (@args);
			}
		}
    }
    return($self->{'_xosd'});
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: State Methods
#:

#: enable altering of attributes
sub attr {
    my $self = $_[0];
    my $name = $_[1];
    unless ($_[2]) {
		return($self->{'_opts'}->{$name}) unless not $self->{'_opts'}->{$name};
		return(undef());
    }
    if ($_[2] == 0 || $_[2] =~ /^NULL$/i) {
		$self->{'_opts'}->{$name} = 0;
    } else {
		$self->{'_opts'}->{$name} = $_[2];
    }
    return($self->{'_opts'}->{$name});
}

#: return the last response data as an ARRAY
sub ra {
    my $self = shift();
    $self->_debug((join(" | ",(caller())))." > ra() > rset: ".((@_) ? "@_" : 'NULL'),3);
    $self->{'_state'}->{'ra'} = ($_[0] =~ /^null$/i) ? [ 0 ] : [ @_ ] unless not @_;
    my $aref = $self->{'_state'}->{'ra'};
	ref($aref) eq "ARRAY" or $aref = [];
    return(@{$aref});
}

#: return the last response data as a SCALAR
sub rs {
    my $self = shift();
    my $rset = $_[0];
    $self->_debug((join(" | ",(caller())))." > rs() > rset: ".(($rset) ? $rset : 'NULL'),3);
    $self->{'_state'}->{'rs'} = ($rset =~ /^null$/i) ? 0 : $rset unless not $rset;
    return($self->{'_state'}->{'rs'});
}

#: return the last exit code as a SCALAR
sub rv {
    my $self = shift();
    my $rset = $_[0];
    $self->_debug((join(" | ",(caller())))." > rv() > rset: ".(($rset) ? $rset : 'NULL'),3);
    $self->{'_state'}->{'rv'} = ($rset =~ /^null$/i) ? '0' : $rset unless not $rset;
    return($self->{'_state'}->{'rv'});
}

#: report on the state of the last dialog variant execution.
sub state {
    my $self = shift();
    my $rv = $self->rv() || 0;
    $self->_debug((join(" | ",(caller())))." > state() > is: ".($rv||'NULL'),2);
    if ($rv == 1 or $rv == 129) {
		return("CANCEL");
    } elsif ($rv == 2) {
		return("HELP");
    } elsif ($rv == 3) {
		return("EXTRA");
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
#: Execution Methods
#:

#: execute a simple command (return the exit code only);
sub command_state {
    my $self = $_[0];
    my $cmnd = $_[1];
    $self->_debug("command: ".$cmnd,1);
    system($cmnd . " 2>&1 > /dev/null");
    my $rv = $? >> 8;
    $self->_debug("command rv: ".$rv,2);
    return($rv);
}

#: execute a command and return the exit code and one-line SCALAR
sub command_string {
    my $self = $_[0];
    my $cmnd = $_[1];
    $self->_debug("command: ".$cmnd,1);
    chomp(my $text = `$cmnd 2>&1`);
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
    chomp(my $text = `$cmnd 2>&1`);
    my $rv = $? >> 8;
    $self->_debug("command ra: ".$rv." '".$text."'",2);
    return([split(/\n/,$text)]) unless defined wantarray;
    return (wantarray) ? ($rv,[split(/\n/,$text)]) : [split(/\n/,$text)];
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Utility Methods
#:


#: make some noise
sub beep {
    my $self = $_[0];
    return($self->_beep(1));
}

#: Clear terminal screen.
sub clear {
    my $self = $_[0];
    return($self->_clear(1));
}

# word-wrap a line
sub word_wrap {
    my $self = shift();
    my $width = shift() || 65;
    my $indent = shift() || "";
    my $sub_indent = shift() || "";
    $Text::Wrap::columns = $width;
    my @strings = wrap($indent, $sub_indent, @_);
    return(@strings);
}

# generate a temporary file name
sub gen_tempfile_name {
    my $self = $_[0];
    my $template = $self->{'_opts'}->{'tempfiletemplate'} || "UI_Dialog_tempfile_XXXXX";
    if (eval("require File::Temp; 1")) {
		use File::Temp qw( tempfile );
		my ($fh,$filename) = tempfile( UNLINK => 1 ) or croak( "Can't create tempfile: $!" );
		return($filename) unless wantarray;
		return($fh,$filename);
    } else {
		my $mktemp = $self->_find_bin('mktemp');
		if ($mktemp && -x $mktemp) {
			chomp(my $tempfile = `$mktemp "$template"`);
			return($tempfile);
		} else {
			#pseudo-random filename coming up!
			my $tempdir = "/tmp";
			unless (-d $tempdir) {
				if (-d "/var/tmp") {
					$tempdir = "/var/tmp";
				} else {
					$tempdir = ".";
				}
			}
			$self->gen_random_string(5);
			my $tempfile = "UI_Dialog_tempfile_".$self->gen_random_string(5);
			while (-e $tempdir."/".$tempfile) {
				$self->gen_random_string(5);
				$tempfile = "UI_Dialog_tempfile_".$self->gen_random_string(5);
			}
			return($tempdir."/".$tempfile);
		}
    }
}

# generate a random string as a (possibly) suitable failover option in the
# event that File::Temp is not installed and the 'mktemp' program does not
# exist in the path.
sub gen_random_string {
    my $self = $_[0];
    my $length = $_[1] || 5;
    my $string = "";
    my $counter = 0;
    while ($counter < $length) {
		# 33 - 127
		my $num = rand(128);
		while ($num < 33 or $num > 127) { $num = rand(128); }
		$string .= chr($num);
		$counter++;
    }
    return($string);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Widget Wrapping Methods
#:

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: file select
sub fselect {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);

    $self->rv('NULL');
    $self->rs('NULL');
    $self->ra('NULL');

    $self->_beep($args->{'beepbefore'});

    my $cwd = abs_path();
    $args->{'path'} ||= abs_path();
    my $path = $args->{'path'};
    if (!$path || $path =~ /^(\.|\.\/)$/) { $path = $cwd; }
    my $file;
    my ($menu,$list) = ([],[]);
  FSEL: while ($self->state() ne "ESC" && $self->state() ne "CANCEL") {
		my $entries = ($args->{'dselect'}) ? ['[new directory]'] :  ['[new file]'];
		($menu, $list) = $self->_list_dir($path,$entries);
		$file = $self->menu(height=>$args->{'height'},width=>$args->{'width'},listheight=>($args->{'listheight'}||$args->{'menuheight'}),
							title=>$args->{'title'},text=>$path,list=>$menu);
		if ($self->state() eq "CANCEL") {
			$self->rv(1);
			$self->rs('NULL');
			$self->ra('NULL');
			last FSEL;
		} elsif ($file ne "") {
			if ($list->[($file - 1 || 0)] =~ /^\[(new\sdirectory|new\sfile)\]$/) {
				my $nfn;
				while (!$nfn || -e $path."/".$nfn) {
					$nfn = $self->inputbox(height=>$args->{'height'},width=>$args->{'width'},title=>$args->{'title'},
										   text=>'Enter a name (will have a base directory of: '.$path.')');
					next FSEL if $self->state() eq "ESC" or $self->state() eq "CANCEL";
					if (-e $path."/".$nfn) { $self->msgbox(title=>'error',text=>$path."/".$nfn.' already exists! Choose another name please.'); }
				}
				$file = $path."/".$nfn;
				$file =~ s!/$!! unless $file =~ m!^/$!;
				$file =~ s!/\./!/!g; $file =~ s!/+!/!g;
				last FSEL;
			} elsif ($list->[($file - 1 || 0)] eq "../") {
				$path = dirname($path);
			} elsif ($list->[($file - 1 || 0)] eq "./") {
				$file = $path;
				$file =~ s!/$!! unless $file =~ m!^/$!;
				$file =~ s!/\./!/!g; $file =~ s!/+!/!g;
				last FSEL;
			} elsif (-d $path."/".$list->[($file - 1 || 0)]) {
				$path = $path."/".$list->[($file - 1 || 0)];
			} elsif (-e $path."/".$list->[($file - 1 || 0)]) {
				$file = $path."/".$list->[($file - 1 || 0)];
				$file =~ s!/$!! unless $file =~ m!^/$!;
				$file =~ s!/\./!/!g; $file =~ s!/+!/!g;
				last FSEL;
			}
		}
		$file = undef();
		$path =~ s!(/*)!/!; $path =~ s!/\./!/!g;
    }
    $self->_beep($args->{'beepafter'});
    my $rv = $self->rv();
    $self->ra('NULL');
    if ($rv && $rv >= 1) {
		$self->rs('NULL');
		return(0);
    } else {
		$self->rs($file);
		return($file);
    }
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: directory selection
sub dselect {
    my $self = shift();
    my $caller = (caller(1))[3] || 'main';
    $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
    if ($_[0] && $_[0] eq 'caller') { shift(); $caller = shift(); }
    my $args = $self->_pre($caller,@_);
    my $dirname;
    $self->rv('NULL');
    $self->rs('NULL');
    $self->ra('NULL');
    while (not $dirname && $self->state() !~ /^(CANCEL|ESC|ERROR)$/) {
		$dirname = $self->fselect(@_,'dselect',1);
		if ($self->state() =~ /^(CANCEL|ESC|ERROR)$/) {
			return(0);
		}
		unless (not $dirname) {
			# if it's a directory or not exist (assume new dir)
			unless (-d $dirname || not -e $dirname) {
				$self->msgbox( text => $dirname . " is not a directory.\nPlease select a directory." );
				$dirname = undef();
			}
		}
    }
    return($dirname||'');
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Backend Methods
#:

sub _pre {
    my $self = shift();
    my $caller = shift();
    my $args = $self->_merge_attrs(@_);
    $args->{'caller'} = $caller;
    my $class = ref($self);

    my $CODEREFS = $args->{'callbacks'};
    if (ref($CODEREFS) eq "HASH") {
		my $PRECODE = $CODEREFS->{'PRE'};
		if (ref($PRECODE) eq "CODE") {
			&$PRECODE($args,$self->state());
		}
    }

    $self->_beep($args->{'beepbefore'});
    $self->_clear($args->{'clearbefore'});
    return($args);
}

sub _post {
    my $self = shift();
    my $args = shift() || {};
    my $class = ref($self);

    $self->_beep($args->{'beepafter'});
    $self->_clear($args->{'clearafter'});

    my $CODEREFS = $args->{'callbacks'};
    if (ref($CODEREFS) eq "HASH") {
		my $state = $self->state();
		if ($state eq "OK") {
			my $OKCODE = $CODEREFS->{'OK'};
			if (ref($OKCODE) eq "CODE") {
				&$OKCODE($args);
			}
		} elsif ($state eq "ESC") {
			my $ESCCODE = $CODEREFS->{'ESC'};
			if (ref($ESCCODE) eq "CODE") {
				&$ESCCODE($args);
			}
		} elsif ($state eq "CANCEL") {
			my $CANCELCODE = $CODEREFS->{'CANCEL'};
			if (ref($CANCELCODE) eq "CODE") {
				&$CANCELCODE($args);
			}
		}
		my $POSTCODE = $CODEREFS->{'POST'};
		if (ref($POSTCODE) eq "CODE") {
			&$POSTCODE($args,$state);
		}
    }

    return(1);
}

#: merge the arguments with the default attributes, and arguments override defaults.
sub _merge_attrs {
    my $self = shift();
    my $args = (@_ % 2) ? { @_, '_odd' } : { @_ };
    my $defs = $self->{'_opts'};
    foreach my $def (keys(%$defs)) {
		$args->{$def} = $defs->{$def} unless $args->{$def};
    }
    # alias 'filename' and 'file' to path
    $args->{'path'} = (($args->{'filename'}) ? $args->{'filename'} :
					   ($args->{'file'}) ? $args->{'file'} :
					   ($args->{'path'}) ? $args->{'path'} : "");

    if ($args->{'title'} && length($args->{'title'})) {
		$args->{'title'} = $self->_esc_text($args->{'title'});
    }
    if ($args->{'backtitle'} && length($args->{'backtitle'})) {
		$args->{'backtitle'} = $self->_esc_text($args->{'backtitle'});
    }
	#     if ($args->{'text'} && length($args->{'text'})) {
	# 	my $text = $args->{'text'};
	# 	if (ref($text) eq "ARRAY") {
	# 	    $args->{'text'} = $self->_esc_text_array($args->{'text'});
	# 	} else {
	# 	    $args->{'text'} = $self->_esc_text($args->{'text'});
	# 	}
	#     }
    if ($args->{'list'} && length($args->{'list'})) {
		my $list = $args->{'list'};
		if (ref($list) eq "ARRAY") {
			my $total = @{$list};
			for (my $i = 0; $i < $total; $i++) {
				my $elem = $list->[$i];
				if (ref($elem) eq "ARRAY") {
					my $elem_total = @{$elem};
					for (my $j = 0; $j < $elem_total; $j++) {
						$elem->[$j] = $self->_esc_text($elem->[$j]);
					}
				} else {
					$list->[$i] = $self->_esc_text($list->[$i]);
				}
			}
		} else {
			$args->{'list'} = $self->_esc_text($args->{'list'});
		}
    }
    $args->{'clear'} = $args->{'clearbefore'} || $args->{'clearafter'} || $args->{'autoclear'} || 0;
    $args->{'beep'} = $args->{'beepbefore'} || $args->{'beepafter'} || $args->{'autobeep'} || 0;
    return($args);
}

#: search through the given paths for a specific variant
sub _find_bin {
    my $self = $_[0];
    my $variant = $_[1];
    $self->{'PATHS'} = ((ref($self->{'PATHS'}) eq "ARRAY") ? $self->{'PATHS'} :
						($self->{'PATHS'}) ? [ $self->{'PATHS'} ] :
						[ '/bin', '/usr/bin', '/usr/local/bin', '/opt/bin' ]);
    foreach my $PATH (@{$self->{'PATHS'}}) {
		return($PATH . '/' . $variant)
		 unless not -x $PATH . '/' . $variant;
    }
    return(0);
}

#: clean the text arguments of all colour codes, alignments and attributes.
sub _strip_text {
    my $self = $_[0];
    my $text = $_[1];
    $text =~ s!\\Z[0-7bBuUrRn]!!gmi;
    $text =~ s!\[[AC]=\w+\]!!gmi;
    $text =~ s!\[/?[BURN]\]!!gmi;
    return($text);
}
sub _esc_text {
    my $self = $_[0];
    my $text = $_[1];
    unless (ref($text)) {
		$text =~ s!\"!\\"!gm;
		$text =~ s!\`!\\`!gm;
		$text =~ s!\(!\(!gm;
		$text =~ s!\)!\)!gm;
		$text =~ s!\[!\[!gm;
		$text =~ s!\]!\]!gm;
		$text =~ s!\{!\{!gm;
		$text =~ s!\}!\}!gm;
		$text =~ s!\$!\\\$!gm;
		$text =~ s!\>!\>!gm;
		$text =~ s!\<!\<!gm;
    }
    return($text);
}

#: indent and organize the text argument
sub _organize_text {
    my $self = $_[0];
    my $text = $_[1] || return();
    my $width = $_[2] || 65;
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
				#		$pad = ((($self->{'_opts'}->{'width'} - 5) - length($s_line)) / 2);
				$pad = (($self->{'_opts'}->{'width'} - length($s_line)) / 2);
			} elsif (uc($align) eq "LEFT" || uc($align) eq "L") {
				$pad = 0;
			} elsif (uc($align) eq "RIGHT" || uc($align) eq "R") {
				#		$pad = (($self->{'_opts'}->{'width'} - 5) - length($s_line));
				$pad = (($self->{'_opts'}->{'width'}) - length($s_line));
			}
		}
		if ($pad) { $text .= (" " x $pad).$line."\n"; }
		else { $text .= $line."\n"; }
    }
    $text = $self->_strip_text($text);
    chomp($text);
    return($text);
}

#: is this a BSD system?
sub _is_bsd {
    my $self = shift();
    return(1) if $^O =~ /bsd/i;
    return(0);
}

#: gather a list of the contents of a directory and return it in
#: two forms, one is the "simple" list of all the filenames and the
#: other is a 'menu' list corresponding to the simple list.
sub _list_dir {
    my $self = shift();
    my $path = shift() || return();
    my $pref = shift();
    my (@listing,@list);
    if (opendir(GETDIR,$path)) {
		my @dir_data = readdir(GETDIR);
		closedir(GETDIR);
		if ($pref) { push(@listing,@{$pref}); }
		foreach my $dir (sort(grep { -d $path."/".$_ } @dir_data)) { push(@listing,$dir."/"); }
		foreach my $item (sort(grep { !-d $path."/".$_ } @dir_data)) { push(@listing,$item); }
		my $c = 1;
		foreach my $item (@listing) { push(@list,"$c",$item); $c++; }
		return(\@list,\@listing);
    } else {
		return("failed to read directory: ".$path);
    }
}

sub _debug {
    my $self = $_[0];
    my $mesg = $_[1] || 'null debug message given!';
    my $rate = $_[2] || 1;
    return() unless $self->{'_opts'}->{'debug'} and $self->{'_opts'}->{'debug'} >= $rate;
    chomp($mesg);
    print STDERR "Debug: ".$mesg."\n";
}
sub _error {
    my $self = $_[0];
    my $mesg = $_[1] || 'null error message given!';
    chomp($mesg);
    print STDERR "Error: ".$mesg."\n";
}

#: really make some noise
sub _beep {
    my $self = $_[0];
    my $beep = $_[1];
    unless (not $beep) {
		if (-x $self->{'_opts'}->{'beepbin'}) {
			return(eval { system($self->{'_opts'}->{'beepbin'}); 1; });
		} else {
			return (1) unless $ENV{'TERM'} && $ENV{'TERM'} ne "dumb";
			print STDERR "\a";
		}
    }
    return(1);
}

#: The actual clear action.
sub _clear {
    my $self = $_[0];
    my $clear = $_[1] || 0;
    # Useless with GUI based variants so we return here.
    # Is the use of the "dumb" TERM appropriate? need feedback.
    return (1) unless $ENV{'TERM'} && $ENV{'TERM'} ne "dumb";
    unless (not $clear and not $self->{'_opts'}->{'autoclear'}) {
		$self->{'_clear'} ||= `clear`;
		print STDOUT $self->{'_clear'};
    }
    return(1);
}



1;
