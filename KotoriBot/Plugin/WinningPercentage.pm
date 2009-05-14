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

	while ($message =~ /\b(\d+)勝(\d+)敗\b/ig) {
		my $wins = $1;
		my $lose = $2;

		if ($wins + $lose > 0) {
			$channel->notice(sprintf("勝率 %4.2f%%", $wins * 100.0 / ($wins + $lose)));
		}
	}
}

###############################################################################

return 1;
