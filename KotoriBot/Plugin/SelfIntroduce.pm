# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::SelfIntroduce;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_my_join() {
	my($self) = @_;

	$self->{channel}->suppress_introduce();
	$self->{channel}->notice("音無小鳥があなたをサポートします♪ (" . KotoriBot::Core->longversion() . ")");
}

###############################################################################

return 1;
