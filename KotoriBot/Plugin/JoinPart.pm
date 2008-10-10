# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::JoinPart;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	while ($message =~ /\b(join|part):(\#[^\s]+)\b/ig) {
		my $cmd = $1;
		my $channelname = $2;

		if ($cmd eq "join") {
			# XXX
		} else {
			# part
			my $channel_to_part = $self->{channel}->server()->channel($channelname);
			$channel_to_part->part() if $channel_to_part;
		}
	}
}

###############################################################################

return 1;
