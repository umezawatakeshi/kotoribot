# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::RemoteNotice;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	if ($message =~ /^\\\\([^\\]+)(.*)/) {
		my $nick = $1;
		my $cmd = $2;
		return if $nick ne $channel->server()->irc()->nick_name();
		$message = $cmd;
	}

	if ($message =~ /^\\remotenotice +(\#\S+) +(.+)/) {
		my $rchannelname = $1;
		my $rmsg = $2;

		my $rchannel = $channel->server()->channel($rchannelname);
		if (defined($rchannel)) {
			$rchannel->notice($rmsg);
		} else {
			$channel->notice_error("no such channel");
		}
	} elsif ($message =~ /^\\globalnotice +(.+)/){
		my $rmsg = $1;

		my @channels = $channel->server()->channels();
		foreach my $rchannel (@channels) {
			$rchannel->notice($rmsg) if ($rchannel != $channel);
		}
	} elsif ($message =~ /^\\universalnotice +(.+)/){
		my $rmsg = $1;

		my @channels;
		foreach my $server (KotoriBot::Core->servers()) {
			push(@channels, $server->channels());
		}
		foreach my $rchannel (@channels) {
			$rchannel->notice($rmsg) if ($rchannel != $channel);
		}
	}
}

###############################################################################

return 1;
