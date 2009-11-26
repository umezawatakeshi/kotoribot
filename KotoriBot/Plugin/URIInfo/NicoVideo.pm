# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::NicoVideo;

use strict;
use warnings;
use utf8;

use HTML::HeadParser;
use HTTP::Request::Common;
use XML::DOM;
use XML::DOM::XPath;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $auth_mail = undef;
my $auth_pass;

my $wwwhostmatch = qr!http://www\.nicovideo\.jp/!;
my $langhostmatch = qr!http://(tw|es|de)\.nicovideo\.jp/!;
my $livehostmatch = qr!http://live\.nicovideo\.jp/!;

my $watchmatch = qr!http://(?:www|tw|es|de)\.nicovideo\.jp/watch/(..\d+)!;
my $comwatchmatch = qr!http://(?:www|tw|es|de)\.nicovideo\.jp/watch/(\d+)!;
my $livematch = qr!http://live\.nicovideo\.jp/(?:watch|gate)/..\d+!;
my $thumbinfomatch = qr!http://ext\.nicovideo\.jp/api/getthumbinfo/(..\d+)!;

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
		$uriinfo->add_transform_plugin($self, $watchmatch);
		$uriinfo->add_output_plugin($self, qr!http://(?:www|live|tw|es|de|ext)\.nicovideo\.jp/.*!, qr!(?:text|application)/x?html(?:\+xml)?!);
		$uriinfo->add_output_plugin($self, $watchmatch, qr!(?:text|application)/xml!);
	}

	my $http = $channel->plugin("KotoriBot::Plugin::URIInfo::HTTP");
	$self->{http} = $http;

	my $html = $channel->plugin("KotoriBot::Plugin::URIInfo::HTML");
	$self->{html} = $html;
}

sub transform_uri {
	my($self, $context, $uri) = @_;

	# 2009/11/19 現在、コミュ動画の URL に関しては getthumbinfo が使えない
	if ($uri =~ /$watchmatch/ && $uri !~ /$comwatchmatch/) {
		my $movid = $1;
		my $req = HTTP::Request::Common::GET("http://ext.nicovideo.jp/api/getthumbinfo/$movid");
		$self->{http}->do_request($context, $req);
	} else {
		$self->{http}->transform_uri($context, $uri);
	}
}

sub output_content {
	my($self, $context, $content, $ct, $clen, $uri) = @_;

	if ($uri =~ /$watchmatch/ && $ct =~ m!(?:text|application)/xml!) {
		$self->output_thumbinfo($context, $content, $ct, $clen, $uri);
		return;
	}

	# ログインフォームあるいはそのリンクが含まれるかどうか
	if (defined($auth_mail) &&
			($content =~ m!\<form [^<>]*action=\"https://secure.nicovideo.jp/secure/login! ||
			 $content =~ m!\<a [^<>]*href=\"https://secure.nicovideo.jp/secure/login_form!)) {
		# 一度ログインを試行したにも関わらず出てくる場合はログインに失敗している。
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
			$addparam{next_url} = "$'";
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
		if ($content =~ m!放送者:<strong class=\"nicopedia\">(?:<a href=\"[^>]*?>)?([^<]+?)(?:</a>)?</strong>さん!) {
			push(@annotation, $1);
		} elsif ($content =~ m!<b>放送者：</b><span class=\"nicopedia\">(?:<a href=\"[^>]*?>)?([^<]+?)(?:</a>)?</span>さん!) {
			push(@annotation, $1);
		}
		if ($content =~ m!<strong>(\d\d\d\d年\d\d月\d\d日 \d\d)：(\d\d)</strong>  からスタートしています!) {
			push(@annotation, "$1:$2 開始");
		} elsif ($content =~ m!<\w+ class=\"date\">\s*<strong>(\d\d月\d\d日)</strong>\s*開演：<strong>(\d\d:\d\d)</strong>!s) {
			push(@annotation, "$1 $2 開演予定");
		} elsif ($content =~ m!<\w+ class=\"date\">\s*<strong>(\d\d月\d\d日)</strong>\s*開場：<strong>(\d\d:\d\d)</strong>\s*開演：<strong>(\d\d:\d\d)</strong>!s) {
			push(@annotation, "$1 $2 開場予定 $3 開演予定");
		}

		my $title = $parser->header("title");
		if ($content =~ m!<h2 class=\"\">([^<]+)</h2>!) {
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

sub output_thumbinfo {
	my($self, $context, $content, $ct, $clen, $uri) = @_;

	my $parser = XML::DOM::Parser->new();
	my $doc = $parser->parse($content);

	if (findnode($doc, '//nicovideo_thumb_response')->getAttribute("status") ne "ok") {
		$context->notice_error("動画情報の取得に失敗しました - ニコニコ動画");
		return;
	}

	my $title = findnode($doc, '//title/text()')->getData();
	my $len = findnode($doc, '//length/text()')->getData();
	my $view = comsep(findnode($doc, '//view_counter/text()')->getData());
	my $com = comsep(findnode($doc, '//comment_num/text()')->getData());
	my $mylist = comsep(findnode($doc, '//mylist_counter/text()')->getData());
	my $size = sprintf("%.1fMB", findnode($doc, '//size_high/text()')->getData() / (1024*1024));
	findnode($doc, '//first_retrieve/text()')->getData() =~ /^(\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)\+09:00$/;
	my $timestamp = "$1 $2";

	my @tagnodes = $doc->findnodes('//tags[@domain="jp"]/tag');
	# ロックされているタグは太字にする。
	my $tags = join(", ", map { my $text = $_->getFirstChild()->getData(); $_->getAttribute("lock") ? "\x02$text\x0f" : $text } @tagnodes);

	$context->notice("$title - ニコニコ動画 ($timestamp, $len, $size, 再生 $view, コメ $com, マイリス $mylist) ($tags)");
}

sub findnode($$) {
	my($doc, $path) = @_;

	my @nodes = $doc->findnodes($path);
	return $nodes[0];
}

# 3桁カンマ区切りにする。（整数用）
sub comsep($) {
	my($val) = @_;

	$val =~ s/(.)(............)$/$1,$2/;
	$val =~ s/(.)(.........)$/$1,$2/;
	$val =~ s/(.)(......)$/$1,$2/;
	$val =~ s/(.)(...)$/$1,$2/;

	return $val;
}

###############################################################################

return 1;
