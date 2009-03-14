# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::Dice;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

# ちなみに dice は複数形で、
# 単数形は die（米・英古）または dice（米略・英）であるらしい。

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	while ($message =~ /\b(|s|c|sc)dice:(\d*)d(\d*)\b/ig) {
		my($type, $numdice, $faces) = ($1, $2, $3);
		my $needsort = $type =~ /s/;
		my $combination = $type =~ /c/;

		if ($numdice eq "") { $numdice = 1; }
		if ($faces eq "") { $faces = 6; }

		next unless ($numdice > 0 && $faces > 0);

		if ($numdice > 20) {
			$channel->notice_error("Too many dice.");
		} elsif ($combination && $numdice > $faces) {
			$channel->notice_error("Dice must not be more than faces for cdice/scdice.");
		} else {
			my $msg;
			my $total = 0;
			my @nums;

			for (my $i = 0; $i < $numdice; $i++) {
				my $thisdice = int(rand($faces)) + 1;
				redo if ($combination && scalar(grep { $_ == $thisdice } @nums) > 0); # 手抜き
				push(@nums, $thisdice);
				$total += $thisdice;
			}
			if ($needsort) {
				@nums = sort { $a <=> $b } @nums;
			}

			$msg = sprintf("%dD%d = %s", $numdice, $faces, join(" + ", @nums));
			$msg .= " = $total" if ($numdice > 1);

			$channel->notice($msg);
		}
	}
}

###############################################################################

return 1;
