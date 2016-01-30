package UI::Dialog::KDE;
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
use UI::Dialog;

BEGIN {
    use vars qw( $VERSION @ISA );
    @ISA = qw( UI::Dialog );
    $VERSION = '1.13';
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Constructor Method
#:

sub new {
    my $proto = shift();
    my $class = ref($proto) || $proto;
    my $cfg = {@_} || {};
    my $self = {};
    bless($self, $class);

    $self->{'debug'} = $cfg->{'debug'} || 0;

	#: Dynamic path discovery...
	my $CFG_PATH = $cfg->{'PATH'};
	if ($CFG_PATH) {
		if (ref($CFG_PATH) eq "ARRAY") { $self->{'PATHS'} = $CFG_PATH; }
		elsif ($CFG_PATH =~ m!:!) { $self->{'PATHS'} = [ split(/:/,$CFG_PATH) ]; }
		elsif (-d $CFG_PATH) { $self->{'PATHS'} = [ $CFG_PATH ]; }
	} elsif ($ENV{'PATH'}) { $self->{'PATHS'} = [ split(/:/,$ENV{'PATH'}) ]; }
	else { $self->{'PATHS'} = ''; }

    $cfg->{'order'} ||= [ 'kdialog', 'xdialog' ];

    $self->_debug("ENV->UI_DIALOGS: ".($ENV{'UI_DIALOGS'}||'NULL'),2);
    $cfg->{'order'} = [ split(/\:/,$ENV{'UI_DIALOGS'}) ] if $ENV{'UI_DIALOGS'};

    $self->_debug("ENV->UI_DIALOG: ".($ENV{'UI_DIALOG'}||'NULL'),2);
    unshift(@{$cfg->{'order'}},$ENV{'UI_DIALOG'}) if $ENV{'UI_DIALOG'};

    $cfg->{'trust-input'} =
      ( exists $cfg->{'trust-input'}
        && $cfg->{'trust-input'}==1
      ) ? 1 : 0;

    my @opts = ();
    foreach my $opt (keys(%$cfg)) { push(@opts,$opt,$cfg->{$opt}); }

    foreach my $try (@{$cfg->{'order'}}) {
		if ($try =~ /^kdialog$/i) {
			$self->_debug("trying kdialog",2);
			if (eval "require UI::Dialog::Backend::KDialog; 1" && $self->_has_variant('kdialog')) {
				require UI::Dialog::Backend::KDialog;
				$self->{'_ui_dialog'} = new UI::Dialog::Backend::KDialog (@opts);
				$self->_debug("using kdialog",2);
				last;
			} else { next; }
		} elsif ($try =~ /^(?:xdialog||X)$/i) {
			$self->_debug("trying xdialog",2);
			if (eval "require UI::Dialog::Backend::XDialog; 1" && $self->_has_variant('Xdialog')) {
				require UI::Dialog::Backend::XDialog;
				$self->{'_ui_dialog'} = new UI::Dialog::Backend::XDialog (@opts,'XDIALOG_HIGH_DIALOG_COMPAT',1);
				$self->_debug("using xdialog",2);
				last;
			} else { next; }
		} else {
			# we don't know what they're asking for... try UI::Dialog...
			if (eval "require UI::Dialog; 1") {
				require UI::Dialog;
				$self->{'_ui_dialog'} = new UI::Dialog (@opts);
				$self->_debug(ref($self)." unknown backend: '".$try."', using UI::Dialog instead.",2);
				last;
			} else { next; }
		}
    }

    ref($self->{'_ui_dialog'}) or croak("unable to load suitable backend.");

    return($self);
}

1;
