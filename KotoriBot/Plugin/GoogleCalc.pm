# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::GoogleCalc;

use strict;
use warnings;
use utf8;

use Encode;
use HTML::TokeParser;
use LWP;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub new {
	my($class, $channel) = @_;

	my $self = bless(KotoriBot::Plugin->new($channel), $class);

	my $ua = LWP::UserAgent->new();
	$ua->timeout(10);
	$ua->agent(KotoriBot::Core->agent());
	$self->{ua} = $ua;

	return $self;
}

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	if ($message =~ /^\s*gcalc:(.*)$/) {
		my $expr = $1;

		$expr = Encode::encode("utf-8", $expr);
		$expr =~ s/([^\w ])/'%'.unpack('H2', $1)/eg;
		$expr =~ tr/ /+/;

		my $req = HTTP::Request->new("GET" , "http://www.google.com/search?q=$expr&hl=ja&ie=utf-8&oe=utf-8");
		my $res = $self->{ua}->request($req);

		if ($res->code() !~ /^2/) {
			$channel->notice("\x034Error:\x03 " . $res->status_line());
			return;
		}

		my $content = Encode::decode("utf-8", $res->content);
		my $parser = HTML::TokeParser->new(\$content);
		$parser->{textify} = { sup => undef };
		my $result = undef;
		while (my $token = $parser->get_tag("h2")) {
			next unless $token->[1]->{class} eq "r";
			$result = $parser->get_trimmed_text("/h2");
			$result =~ s/\[SUP\]/\^/g;
		}
		$channel->notice($result, "\x034Error:\x03 Invalid Expression");
	}
}

###############################################################################

return 1;
