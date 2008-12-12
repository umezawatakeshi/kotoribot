# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::Dice;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	while ($message =~ /\bdice:(\d*)d(\d*)\b/ig) {
		my($numdice, $faces) = ($1, $2);

		if ($numdice eq "") { $numdice = 1; }
		if ($faces eq "") { $faces = 6; }

		next unless ($numdice > 0 && $faces > 0);

		my $msg = "$numdice"."D$faces = ";
		my $total = 0;

		for (my $i = 0; $i < $numdice; $i++) {
			my $thisdice = int(rand($faces)) + 1;
			$msg .= " + " if ($i != 0);
			$msg .= $thisdice;
			$total += $thisdice;
		}
		$msg .= " = $total" if ($numdice > 1);

		$channel->notice($msg);
	}
}

###############################################################################

return 1;
