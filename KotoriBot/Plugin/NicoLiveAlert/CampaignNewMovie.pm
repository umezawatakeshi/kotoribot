# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::NicoLiveAlert::CampaignNewMovie;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $poller;

sub initialize {
	my($self) = @_;

	$poller = KotoriBot::Plugin::NicoLiveAlert::CampaignNewMovie::Poller->new() unless defined($poller);
	$poller->add($self);
}

sub destroy {
	my($self) = @_;

	$poller->remove($self);
}

sub notice {
	my($self, $message) = @_;

	$self->{channel}->notice($message);
}

###############################################################################

package KotoriBot::Plugin::NicoLiveAlert::CampaignNewMovie::Poller;

use strict;
use warnings;
use utf8;

use LWP;
use HTML::HeadParser;
use POE qw(Component::Client::HTTP);

my $jumpurl = "http://live.nicovideo.jp/new_movie";

sub new {
	my($class) = @_;

	my $self = bless({
		plugins => [],
		prevtime => 0,
		prevurl => "",
	}, $class);

	$self->{ua_alias} = "$self-POE::Component::Client::HTTP";
	POE::Component::Client::HTTP->spawn(
		Alias => $self->{ua_alias},
		Agent => "Kotori/" . KotoriBot::Core->version(),
	);

	my $session = POE::Session->create(
		object_states => [
			$self => [ qw(_start tick done_redirect done_watchpage) ],
		],
		heap => {}
	);
	$self->{session} = $session;

	return $self;
}

sub _start {
	my($self) = @_;

	POE::Kernel->delay("tick", 3);
}

sub tick {
	my($self) = @_;

	POE::Kernel->delay("tick", 3);

	my $now = time();
	return if (int(($self->{prevtime} - 3) / 1800) == int(($now - 3) / 1800));
	$self->{prevtime} = $now;

	my $req = HTTP::Request->new("GET", $jumpurl);

	POE::Kernel->post($self->{ua_alias}, "request", "done_redirect", $req);
}

sub done_redirect {
	my($self, $reqp, $resp) = @_[OBJECT, ARG0, ARG1];

	my $res = $resp->[0];

	if ($res->code() =~ /^3/) {
		my $location = $res->header("Location");
		if ($location =~ m|^http://live.nicovideo.jp/watch/lv\d+|) {
			return if ($self->{prevurl} eq $location);
			$self->{prevurl} = $location;
#			$self->notice("CampaignNewMovie: $location");
			my $req = HTTP::Request->new("GET", $location);
			POE::Kernel->post($self->{ua_alias}, "request", "done_watchpage", $req);
		}
	}
}

# URIInfo の枠組みとは違って、いろいろと決め撃ちで処理している。
# タイトルだけ取れればいいので、ログインする必要もない。
sub done_watchpage {
	my($self, $reqp, $resp) = @_[OBJECT, ARG0, ARG1];

	my $req = $reqp->[0];
	my $res = $resp->[0];
	my $url = $req->uri();
	my $content = Encode::decode("utf8", $res->content());
	my $parser = HTML::HeadParser->new();

	$parser->parse($content);
	$parser->eof();

	my $title = $parser->header("title");
	$self->notice("CampaignNewMovie: $url $title");
}

sub add {
	my($self, $plugin) = @_;

	push(@{$self->{plugins}}, $plugin);
}

sub remove {
	my($self, $plugin) = @_;

	@{$self->{plugins}} = grep { $_ != $plugin } @{$self->{plugins}};
}

sub notice {
	my($self, $message) = @_;

	foreach my $plugin (@{$self->{plugins}}) {
		$plugin->notice($message);
	}
}

###############################################################################

return 1;
