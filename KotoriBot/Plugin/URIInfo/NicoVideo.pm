# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::NicoVideo;

use strict;
use warnings;
use utf8;

use HTML::HeadParser;
use HTTP::Request::Common;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $auth_mail = undef;
my $auth_pass;

my $wwwhostmatch = qr!http://www\.nicovideo\.jp/!;
my $langhostmatch = qr!http://(tw|es|de)\.nicovideo\.jp/!;
my $livehostmatch = qr!http://live\.nicovideo\.jp/!;

my $watchmatch = qr!http://(?:www|tw|es|de)\.nicovideo\.jp/watch/..\d+!;
my $livematch = qr!http://live\.nicovideo\.jp/(?:watch|gate)/..\d+!;

# パスワードファイルをチェック。
# あまりイケてる方法ではないように思える。
if (open(NICOPASS, "<nicopass.txt")) {
	$auth_mail = <NICOPASS>; chomp($auth_mail);
	$auth_pass = <NICOPASS>; chomp($auth_pass);
	close(NICOPASS);
}

sub initialize {
	my($self) = @_;
	my $channel = $self->{channel};

	my $uriinfo = $channel->plugin("KotoriBot::Plugin::URIInfo");
	if ($uriinfo) {
		$uriinfo->add_output_plugin($self, qr!http://(?:www|live|tw|es|de)\.nicovideo\.jp/.*!, qr!(?:text|application)/x?html(?:\+xml)?!);
	}

	my $http = $channel->plugin("KotoriBot::Plugin::URIInfo::HTTP");
	$self->{http} = $http;

	my $html = $channel->plugin("KotoriBot::Plugin::URIInfo::HTML");
	$self->{html} = $html;
}

sub output_content {
	my($self, $context, $content, $ct, $clen, $uri) = @_;

	# ログインフォームが含まれるかどうか
	if (defined($auth_mail) && $content =~ m!\<form [^<>]*action=\"https://secure.nicovideo.jp/secure/login!) {
		# 一度ログインを試行したにも関わらずログインフォームが出てくる場合はログインに失敗している。
		if ($context->{"KotoriBot::Plugin::URIInfo::NicoVideo"}->{login}) {
			$context->process_error("ログインに失敗しました。");
			return;
		}

		$context->notice("ニコニコ動画にログインしています...");

		my %addparam;
		# なんで Referer を使わないんだろう…
		if ($uri =~ $wwwhostmatch) {
			$addparam{next_url} = "/$'";
			$addparam{site} = "niconico";
		} elsif ($uri =~ $langhostmatch) {
			$addparam{next_url} = "/$'";
			$addparam{site} = "$1niconico";
		} elsif ($uri =~ $livehostmatch) {
			$addparam{next_url} = "/$'";
			$addparam{site} = "nicolive";
		}

		my $req = HTTP::Request::Common::POST(
			"https://secure.nicovideo.jp/secure/login",
			{
				mail => $auth_mail,
				password => $auth_pass,
				%addparam,
			}
		);
		# 認証が成功したら同じ URL にリダイレクトされるので、ループ検出は無効にする。
		$context->disable_loop_detection();
		$context->{"KotoriBot::Plugin::URIInfo::NicoVideo"}->{login} = 1;
		$self->{http}->do_request($context, $req);
		return;
	}

	if ($uri =~ $watchmatch) {
		my $parser = HTML::HeadParser->new();

		$parser->parse($content);
		$parser->eof();

		$context->notice_redirects();
		$context->notice($parser->header("title") . " (" . scalar($parser->header("X-Meta-Keywords")) . ")");
	} elsif ($uri =~ $livematch) {
		my $parser = HTML::HeadParser->new();

		$parser->parse($content);
		$parser->eof();

		my @annotation;
		if ($content =~ m!放送者:<strong class=\"nicopedia\">(.+)</strong>さん!) {
			push(@annotation, $1);
		} elsif ($content =~ m!<b>放送者：</b><span class=\"nicopedia\">(.+)</span>さん!) {
			push(@annotation, $1);
		}
		if ($content =~ m!<strong>(\d\d\d\d年\d\d月\d\d日 \d\d)：(\d\d)</strong> からスタートしています!) {
			push(@annotation, "$1:$2 開始");
		} elsif ($content =~ m!<p class=\"date\">\s*(\d\d月\d\d日)\s*<br>\s*開演：(\d\d:\d\d)!s) {
			push(@annotation, "$1 $2 開始予定");
		}

		my $title = $parser->header("title");
		if ($content =~ m!<h2 class=\"ttl\">([^<]+)</h2>!) {
			$title = "$1 - $title";
		}

		$context->notice_redirects();
		if (scalar(@annotation) > 0) {
			$context->notice($title . " (" . join(", ", @annotation) . ")");
		} else {
			$context->notice($title);
		}
	} else {
		$self->{html}->output_content($context, $content, $ct, $clen, $uri);
	}
}

###############################################################################

return 1;
