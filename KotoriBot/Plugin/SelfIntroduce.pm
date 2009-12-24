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
	my $msg = $self->{args}->{message} || "音無小鳥があなたをサポートします♪";
	$self->{channel}->notice("$msg (" . KotoriBot::Core->longversion() . ")");
}

###############################################################################

return 1;
