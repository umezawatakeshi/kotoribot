# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::HTTP;

use strict;
use warnings;
use utf8;

use Encode;
use Encode::Guess;
use HTTP::Cookies;
use LWP;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $cookie_jar_obj = HTTP::Cookies->new();

my $httpurlmatch = qr!https?://[\#\%\&\(\)\*\+\,\-\.\/0-9\:\;\=\?\@A-Z\_a-z\~]+!;

# 本来は設定ファイルで設定できるようにするべき。
my @encoding_suspects = qw(euc-jp iso-2022-jp shift_jis);

sub new {
	my($class, $channel) = @_;

	my $self = bless(KotoriBot::Plugin->new($channel), $class);

	my $ua = LWP::UserAgent->new();
	$ua->timeout(10);
	$ua->max_redirect(0);
	$ua->max_size(32 * 1024); # 32KB
	$ua->cookie_jar($cookie_jar_obj);
	$ua->agent(KotoriBot::Core->agent());
	$self->{ua} = $ua;

	return $self;
}

sub initialize {
	my($self) = @_;

	my $uriinfo = $self->{channel}->plugin("KotoriBot::Plugin::URIInfo");
	if ($uriinfo) {
		$uriinfo->add_transform_plugin($self, $httpurlmatch);
	}
}

sub transform_uri {
	my($self, $context, $uri) = @_;

	my $req = HTTP::Request->new("GET" , $uri);
	$self->do_request($context, $req);
}

sub do_request {
	my($self, $context, $req) = @_;

	my $res = $self->{ua}->request($req);
	$self->done_request($context, $res);
}

sub done_request {
	my($self, $context, $res) = @_;

	if ($res->code() !~ /^2/) {
		my $location = $res->header("Location");
		if ($location) {
			$context->process_redirect($location, "HTTP " . $res->status_line());
		} else {
			$context->process_error($res->status_line());
		}
		return;
	}

	if (!$res->content_type) {
		$context->process_error("Content-Type Undefined");
	} else {
		my $content = $res->content;
		if ($res->content_type =~ m|text/|) {
			my @ct = $res->header("Content-Type"); # HTML 中の <meta http-equiv="Content-Type"> も一緒に返ってくる。
			my @charsets = grep(!/^none$/i, map { s/^charset=//i; $_; } grep(/^charset=/i, map { split(/[;\s]+/, $_); } reverse @ct));
			my $charset = $charsets[0];

			my $enc = undef;
			if (defined($charset)) {
				$enc = Encode::find_encoding($charset);
				if (!ref($enc)) {
					$enc = undef;
				}
			}

			if (!defined($enc)) {
				$enc = guess_encoding($content, @encoding_suspects);
				if (!ref($enc)) {
					$enc = Encode::find_encoding("latin-1"); # guess 失敗。仕方ないので latin-1 にする。
				}
			}

			$content = $enc->decode($content);
		}
		my $clen = $res->content_length;
		my $crange = $res->header("Content-Range");
		if (defined($crange)) {
			if ($crange =~ /^bytes\s+(?:\d+-\d+|\*)\/(\d+)$/i) {
				$clen = $1;
			} else {
				$clen = undef;
			}
		}
		$context->process_content($content, $res->content_type, $clen);
	}
}

sub credentials {
	my($self, $hostport, $realm, $user, $pass) = @_;

	$self->{ua}->credentials($hostport, $realm, $user, $pass);
}

sub cookie_jar {
	my($self, $jar) = @_;

	return $self->{ua}->cookie_jar($jar);
}

###############################################################################

return 1;
