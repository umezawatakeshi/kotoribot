# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::OperDeal::OnlyFirst;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_join {
	my($self, $who) = @_;
	my $channel = $self->{channel};

	my $nick = (split(/!/, $who))[0];
	if (scalar($channel->nicks()) == 2 && $channel->am_operator()) {
		$channel->mode("+o", $nick);
	}
}

sub check_deal {
	my($self) = @_;
	my $channel = $self->{channel};

	if (scalar($channel->nicks()) == 2 && $channel->am_operator()) {
		my @nicks = grep { $_ ne $channel->server->irc->nick_name } $channel->nicks();
		$channel->mode("+o", $nicks[0]);
	}
}

sub on_part {
	my($self) = @_;

	$self->check_deal();
}

sub on_kick {
	my($self) = @_;

	$self->check_deal();
}

sub on_quit {
	my($self) = @_;

	$self->check_deal();
}

###############################################################################

return 1;
