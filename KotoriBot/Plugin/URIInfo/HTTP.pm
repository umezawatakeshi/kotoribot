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

my $cookie_jar_obj = HTTP::Cookies->new( file => "cookies.txt" );

my $httpurlmatch = qr!https?://(\#\x21|[\#\%\&\(\)\*\+\,\-\.\/0-9\:\;\=\?\@A-Z\_a-z\~])+!;

# 本来は設定ファイルで設定できるようにするべき。
my @encoding_suspects = qw(euc-jp shift_jis iso-2022-jp);
my $encoding_fallback = "utf-8";

sub new {
	my $class = shift;
	my($channel) = @_;

	my $self = $class->SUPER::new(@_);

	my $ua = LWP::UserAgent->new();
	$ua->timeout(10);
	$ua->max_redirect(0);
	$ua->requests_redirectable([]);
	$ua->max_size($self->{args}->{max_size} || 64 * 1024);
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
	$self->done_request($context, $res, $req);
}

sub done_request {
	my($self, $context, $res, $req) = @_;

	$cookie_jar_obj->save();

	if ($res->code() !~ /^2/) {
		my $location = $res->header("Location");
		if ($location) {
			if ($location =~ m!^/!) {
				$req->uri =~ m!^(https?://[^/]+)/!;
				$location = "$1$location";
			}
			$location =~ s/[\x80-\xff]/sprintf("%%%02X",ord($&))/eg;
			$context->process_redirect($location, "HTTP " . $res->status_line());
		} else {
			$context->process_error($res->status_line());
		}
		return;
	}

	# content_type は array context だと返し方が異なるので、
	# メソッド引数として渡す場合は注意が必要。
	# my $ct = $res->content_type; # $ct = "text/html";
	# my @ct = $res->content_type; # @ct = ("text/html", "charset=utf-8");
	my $ct = $res->content_type;

	if (!$ct) {
		$context->process_error("Content-Type Undefined");
	} elsif (!defined(my $content = $res->decoded_content(charset => "none"))) {
		$context->process_error("Content-Encoding Unknown");
	} else {
		if ($ct =~ m|text/|) {
			my @ct = $res->header("Content-Type"); # HTML 中の <meta http-equiv="Content-Type"> も一緒に返ってくる。
			# ここで、@ct には HTTP ヘッダの Content-Type、meta タグの Content-Type の順番で返ってくる。
			my @charsets = grep(!/^none$/i, map { s/^charset=//i; $_; } grep(/^charset=/i, map { split(/[;\s]+/, $_); } reverse @ct));
			my $charset = $charsets[0];
			my @suspects = ("utf-8", @encoding_suspects);
			unshift(@suspects, $charset) if (defined($charset));

			# Encode::Guess::guess_encoding の挙動がおかしく、
			# ちゃんと guess してくれないので、自前でそれらしい処理を行う。
			my $restlen = length($content);
			my $enc = undef;
			foreach my $name (@suspects) {
				my $try = Encode::find_encoding($name);
				next if (!ref($try));
				eval {
					my $tmp = $content;
					$try->decode($tmp, Encode::FB_QUIET);
					if (length($tmp) < $restlen) {
						$enc = $try;
						$restlen = length($tmp);
					}
				};
			}
			if (!defined($enc)) {
				$enc = Encode::find_encoding($encoding_fallback);
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

		$context->process_content($content, $ct, $clen);
	}
}

sub credentials {
	my($self, $hostport, $realm, $user, $pass) = @_;

	$self->{ua}->credentials($hostport, $realm, $user, $pass);
}

sub cookie_jar {
	my($self) = @_;

	return $self->{ua}->cookie_jar();
}

###############################################################################

return 1;
