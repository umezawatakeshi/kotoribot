# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::PluginHelp;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	if ($message =~ /^\\pluginhelp (\S+)?$/) {
		my $pluginname = $1;
		my @plugins = $channel->plugins();
		foreach my $plugin (@plugins) {
			if (ref($plugin) eq $pluginname) {
				my $helpstring = $plugin->helpstring();
				if (defined($helpstring)) {
					chomp($helpstring);
					my @helpstrings = split(/[\r\n]+/, $helpstring);
					$channel->notice($_) foreach @helpstrings;
				} else {
					$channel->notice("No helpstring for the plugin");
				}
				return;
			}
		}
		$channel->notice("No such plugin");
	}
}

sub helpstring {
	my $pluginname = __PACKAGE__;
	return <<__EOT__;
$pluginname
    プラグインのヘルプを表示するためのプラグイン
\\pluginhelp <プラグイン名>
    指定したプラグインのヘルプを表示します。
__EOT__
}

###############################################################################

return 1;
