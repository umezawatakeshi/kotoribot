# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::WinningPercentage;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	while ($message =~ /(\d+)勝(\d+)(?:敗|負)/ig) {
		my $wins = $1;
		my $lose = $2;
		my $game = $wins + $lose;

		if ($game > 0) {
			$channel->notice(sprintf("%d戦%d勝%d敗 勝率%4.2f%%", $game, $wins, $lose, $wins * 100.0 / $game));
		}
	}
}

###############################################################################

return 1;
