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
	if (scalar($channel->nicks()) == 2) {
		$channel->mode("+o", $nick);
	}
}

###############################################################################

return 1;
