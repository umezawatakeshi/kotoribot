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

	while ($message =~ /\bselfinfo:(plugin[sl]?|version)\b/ig) {
		my $cmd = $1;

		if ($cmd =~ /^plugin/) {
			my @plugins = $channel->plugins();
			if ($cmd eq "pluginl") {
				foreach my $plugin (@plugins) {
					$channel->notice(ref($plugin));
				}
			} else {
				$channel->notice(join(" ", map { ref($_) =~ /([^:]+)$/; $1; } @plugins));
			}
			$channel->notice("total ".scalar(@plugins)." plugins");
		} elsif ($cmd eq "version") {
			$channel->notice(KotoriBot::Core->longversion());
		}
	}
}

###############################################################################

return 1;
