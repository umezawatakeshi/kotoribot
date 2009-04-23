# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::Echo;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	if ($message =~ /^(echo|public|notice):(.*)$/i) {
		my($type, $msg) = ($1, $2);

		if ($type eq "notice") {
			$channel->notice($msg);
		} else {
			$channel->public($msg);
		}
	}
}

###############################################################################

return 1;
