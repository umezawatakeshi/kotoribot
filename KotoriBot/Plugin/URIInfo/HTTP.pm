# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::HTTP;

use strict;
use warnings;
use utf8;

use Encode;
use Encode::Guess;
use LWP;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $httpurlmatch = qr!https?://[\#\%\&\(\)\*\+\,\-\.\/0-9\:\;\=\?\@A-Z\_a-z\~]+!;

# 本来は設定ファイルで設定できるようにするべき。
my @encoding_suspects = qw(euc-jp iso-2022-jp shift_jis);

sub new {
	my($class, $channel) = @_;

	my $self = bless(KotoriBot::Plugin->new($channel), $class);

	my $ua = LWP::UserAgent->new();
	$ua->timeout(5);
	$ua->max_redirect(0);
	$ua->max_size(4 * 1024); # 4KB
	$ua->agent("Kotori/" . KotoriBot::Core->version());
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
	my $res = $self->{ua}->request($req);

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
			my @charsets = grep(!/^none$/i, map { s/^charset=//i; $_; } grep(/^charset=/i, map { split(/[;\s]+/, $_); } @ct));
			my $charset = $charsets[0];

			if (!defined($charset)) {
				my $enc = guess_encoding($content, @encoding_suspects);
				if (ref($enc)) {
					$charset = $enc->name();
				} else {
					$charset = "latin-1"; # guess 失敗。仕方ないので latin-1 にする。
				}
			}

			my $enc = Encode::find_encoding($charset);
			unless (ref($enc)) {
				$context->process_error("Character Encoding Unknown");
				return;
			}
			$content = $enc->decode($content);
		}
		$context->process_content($content, $res->content_type);
	}
}

###############################################################################

return 1;
