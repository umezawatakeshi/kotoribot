# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin;

use strict;
use warnings;
use utf8;

sub new {
	my($class, $channel) = @_;

	return bless({
		channel => $channel,
	}, $class);
}

###############################################################################
#### KotoriBot::Channel から呼ばれるイベントハンドラ

sub initialize() {}
sub destroy() {}

sub on_my_join() {}
sub on_my_part() {}
sub on_my_kick($$) {}

sub on_public($$) {}

sub helpstring { return undef; }

###############################################################################

return 1;
