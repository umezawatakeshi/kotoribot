# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::PrivCommand;

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

	if ($message =~ /^\\privauth(?: +([0-9A-Za-f]+))?$/) {
	} elsif ($message =~ /^\\join +(\#\S+)(?:\s+(\S+))?$/) {
		my $channelname = $1;
		my $password = $2;
		my $channel_to_join = $self->{channel}->server()->channel($channelname);
		if (defined($channel_to_join)) {
			$channel->notice("\x034Error:\x03 Already joined");
		} else {
			$self->{channel}->server()->join_channel($channelname, $password);
		}
	} elsif ($message =~ /^\\part +(\#\S+)(?:\s+(\S+))?$/) {
		my $channelname = $1;
		my $partmsg = $2;
		my $channel_to_part = $self->{channel}->server()->channel($channelname);
		if (defined($channel_to_part)) {
			$channel_to_part->part($partmsg);
			$channel->notice("Parted from $channelname") unless $channelname eq $channel->name();
		} else {
			$channel->notice("\x034Error:\x03 No such channel");
		}
	} elsif ($message =~ /^\\remoteoperdeal +(\#\S+)\s+(\S+)$/) {
		my $channelname = $1;
		my $nick = $2;
		my $channel_to_mode = $self->{channel}->server()->channel($channelname);
		if (defined($channel_to_mode)) {
			$channel_to_mode->mode("+o", $nick);
			$channel->notice("Dealed to $nick at $channelname") unless $channelname eq $channel->name();
		} else {
			$channel->notice("\x034Error:\x03 No such channel");
		}
	} elsif ($message =~ /^\\channel[sl]?$/) {
		my @channelnames = map { $_->name() } $channel->server()->channels();
		if ($message eq "\\channell") {
			$channel->notice($_) foreach @channelnames;
		} else {
			my @names = @channelnames;
			while (scalar(@names) > 0) {
				$channel->notice(join(" ", splice(@names, 0, 10)));
			}
		}
		$channel->notice("total ".scalar(@channelnames)." channels");
	}
}

###############################################################################

return 1;
