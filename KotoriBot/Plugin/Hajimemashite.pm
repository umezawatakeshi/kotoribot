# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::Hajimemashite;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	if ($message =~ /^(?:初|はじ)めましてと[き聞]いて[。！!]?$/) {
		if (!defined($self->{prevtime}) || $self->{prevtime} < time() - 600) {
			$channel->notice("はじめましてと聞いて。とりあえずこれを http://www.nicovideo.jp/watch/sm4563095");
			$channel->notice("あるＩＲＣの風景‐ニコニコ動画(秋) (まこＴＰ,IRC,嘘字幕シリーズ,アイマスＰネタ,はじめましてと聞いて,だいたいあってる,IRCではよくあること)");
		}
		$self->{prevtime} = time();
	}
}

###############################################################################

return 1;
