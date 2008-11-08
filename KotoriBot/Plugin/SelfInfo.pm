# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::SelfInfo;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	if ($message =~ /^\\plugin[sl]?$/) {
		my @pluginnames = map { ref($_) } $channel->plugins();
		if ($message eq "\\pluginl") {
			$channel->notice($_) foreach @pluginnames;
		} else {
			$channel->notice(join(" ", map { s/^KotoriBot::Plugin:://; $_; } @pluginnames));
		}
		$channel->notice("total ".scalar(@pluginnames)." plugins");
	} elsif ($message =~ /^\\version$/) {
		$channel->notice(KotoriBot::Core->longversion());
	}
}

###############################################################################

return 1;
