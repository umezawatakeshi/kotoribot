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

	if ($message =~ /よ[うー]む/) {
		my $wrong = $&;
		if (!defined($self->{prevtime}) || $self->{prevtime} < time() - 20) {
			$channel->notice("$wrong じゃないよ！ ゆーむ だよ！");
		}
		$self->{prevtime} = time();
	}
}

###############################################################################

return 1;
