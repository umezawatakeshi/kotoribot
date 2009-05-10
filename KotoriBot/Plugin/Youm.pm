# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::Youm;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	if ($message =~ /ようむ/) {
		if (!defined($self->{prevtime}) || $self->{prevtime} < time() - 20) {
			$channel->notice("ようむ じゃないよ！ ゆーむ だよ！");
		}
		$self->{prevtime} = time();
	}
}

###############################################################################

return 1;
