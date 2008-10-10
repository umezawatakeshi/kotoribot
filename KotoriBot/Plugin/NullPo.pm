# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::NullPo;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	if ($message =~ /(ぬ|ヌ|ﾇ)\s*(る|ル|ﾙ)\s*(ぽ|ポ|(ほ|ホ|ﾎ)\s*(゜|ﾟ))/) {
		$channel->notice("ガッ");
	}
}

###############################################################################

return 1;
