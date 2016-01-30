package UI::Dialog::Backend::Nautilus;
###############################################################################
#  Copyright (C) 2015  Kevin C. Krinke <kevin@krinke.ca>
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


#
# Please read the POD for copyright and licensing issues.
#

BEGIN {
    use vars qw($VERSION);
    $VERSION = '1.13';
}

sub new {
    my $proto = shift();
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Internal Methods
#:

sub _debug {
    my $self = shift();
    my $mesg = shift() || 'unknown msg';
    my $logfile = '/tmp/nautilus_debug.tmp';
    if (open(NAUTILUSLOGFILE,">>".$logfile)) {
		print NAUTILUSLOGFILE $mesg."\n";
		close(NAUTILUSLOGFILE);
    }
}
sub _is_env {
    my $self = shift();
    return(1)
     unless not $ENV{'NAUTILUS_SCRIPT_SELECTED_FILE_PATHS'}
      and not $ENV{'NAUTILUS_SCRIPT_SELECTED_URIS'}
       and not $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'}
		and not $ENV{'NAUTILUS_SCRIPT_WINDOW_GEOMETRY'};
    return(0);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public (Nautilus Shell Script) Methods
#:

#: Thanks to URI::Escape. Because it's not part of the core Perl, we need to
#: include it here. UI::Dialog shouldn't force other dependancies. This version
#: is modified to strip the prefixing protocol indicator.
sub uri_unescape {
    # Note from RFC1630:  "Sequences which start with a percent sign
    # but are not followed by two hexadecimal characters are reserved
    # for future extension"
    my $self = shift();
    my $str = shift();
    if (@_ && wantarray) {
        # not executed for the common case of a single argument
        my @str = ($str, @_);	# need to copy
        foreach (@str) {
            s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
			s!^\w+\://!!;
        }
        return(@str);
    }
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg if defined $str;
    $str =~ s!^\w+\://!!;
    return($str);
}

#NAUTILUS_SCRIPT_SELECTED_FILE_PATHS: newline-delimited paths for selected files (only if local)
sub paths {
    my $self = shift();
    if ($self->_is_env()) {
		return(split(/\n/,$ENV{'NAUTILUS_SCRIPT_SELECTED_FILE_PATHS'}))
		 unless not $ENV{'NAUTILUS_SCRIPT_SELECTED_FILE_PATHS'};
		my @paths = ();
		foreach my $uri ($self->uris()) {
			my $path = $uri;
            my $desktop = $self->_get_desktop_dir();
			$path =~ s!^x\-nautilus\-desktop\:///trash!$ENV{'HOME'}/.Trash!;
			$path =~ s!^x\-nautilus\-desktop\://!$desktop!;
			push(@paths,$self->uri_unescape($path));
		}
		return(@paths);
    } else { return(0); }
}

#NAUTILUS_SCRIPT_SELECTED_URIS: newline-delimited URIs for selected files
sub uris {
    my $self = shift();
    if ($self->_is_env()) {
		return(split(/\n/,$ENV{'NAUTILUS_SCRIPT_SELECTED_URIS'}));
    } else { return(0); }
}

#NAUTILUS_SCRIPT_CURRENT_URI: URI for current location
sub path {
    my $self = shift();
    return('error') unless $self->_is_env();
    my $URI = $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} || '';
    my $desktop = $self->_get_desktop_dir();
	$URI =~ s!^x\-nautilus\-desktop\:///trash!$ENV{'HOME'}/.Trash!;
	$URI =~ s!^x\-nautilus\-desktop\://!$desktop!;
    return(($self->uri_unescape($URI)||$URI));
}

#NAUTILUS_SCRIPT_CURRENT_URI: URI for current location
sub uri {
    my $self = shift();
    return($ENV{'NAUTILUS_SCRIPT_CURRENT_URI'}) if $self->_is_env();
    return(0);
}

#NAUTILUS_SCRIPT_WINDOW_GEOMETRY: position and size of current window
sub geometry {
    my $self = shift();
    if ($self->_is_env()) {
		#: Width, Height, X, Y
		return($1,$2,$3,$4) if $ENV{'NAUTILUS_SCRIPT_WINDOW_GEOMETRY'} =~ /(\d+)x(\d+)\+(\d+)\+(\d+)/;
    } else { return(0,0,0,0); }
}

sub _get_desktop_dir {
    my $self = shift();
    my $desktop_dir = $ENV{'HOME'} . "/Desktop";
    if ( eval { require Gnome2::GConf; 1; } ) {
        use Gnome2::GConf;
        my $gconf = Gnome2::GConf::Client->get_default();
        $desktop_dir = $ENV{'HOME'}
         if $gconf->get_bool( '/apps/nautilus/preferences/desktop_is_home_dir' );
    } else {
        my $gconf_xml = $ENV{'HOME'} . '/.gconf/apps/nautilus/preferences/%gconf.xml';
        if ( -r $gconf_xml ) {
            if ( open( GCONF, "<" . $gconf_xml ) ) {
                my $RAW = undef;
                {
                    local $/;
                    $RAW = <GCONF>;
                }
                close( GCONF );
                #        <entry name="desktop_is_home_dir" mtime="1090894369" type="bool" value="true">
                if ( $RAW =~ m!\s+[^"]+\"desktop_is_home_dir\"[^"]+\"\d*\"[^"]+\"bool\"\svalue=\"false\"\>! ) {
                    $desktop_dir = $ENV{'HOME'};
                }
            }
        }
    }
    return( $desktop_dir );
}

1;
