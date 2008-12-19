# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::OperDeal;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub check_regain {
	my($self) = @_;
	my $channel = $self->{channel};

	if (scalar($channel->nicks()) == 1) {
		$channel->rejoin();
	}
}

sub on_part {
	my($self) = @_;

	$self->check_regain();
}

sub on_kick {
	my($self) = @_;

	$self->check_regain();
}

sub on_quit {
	my($self) = @_;

	$self->check_regain();
}

###############################################################################

return 1;
