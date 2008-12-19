# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::Tanjoubi;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	if ($message =~ /^お?(?:誕生日|たんじょうび)と[き聞]いて[。！!]?$/) {
		if (!defined($self->{prevtime}) || $self->{prevtime} < time() - 600) {
			$channel->notice("誕生日と聞いて。とりあえずこれを http://www.geocities.jp/makotcollection/notuse/idol/imascomik03.jpg");
			$channel->notice("JPEG image, 517x323, 47,906bytes");
		}
		$self->{prevtime} = time();
	}
}

###############################################################################

return 1;
