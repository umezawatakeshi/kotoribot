# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URLInfo;

use strict;
use warnings;
use utf8;

use Encode;
use Encode::Guess;
use LWP;
use HTML::HeadParser;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

# 本来は設定ファイルで設定できるようにするべき。
my @encoding_suspects = qw(euc-jp iso-2022-jp shift_jis);

sub new {
	my($class, $channel) = @_;

	my $self = KotoriBot::Plugin->new($channel);

	my $ua = LWP::UserAgent->new();
	$ua->timeout(5);
	$ua->max_redirect(0);
	$ua->max_size(4 * 1024 * 1024); # 4MiB
	$self->{ua} = $ua;

	return bless($self, $class);
}

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	while ($message =~ m!((https?|ftp)://[^\!\$\<\>\"\'\{\}\|\\\^\[\]\`\x00-\x20\x7f-\xff]+)!g) {
		my $url = $1;

		$self->do_request($url);
	}
}

sub do_request {
	my($self, $url, $redir) = @_;
	my $channel = $self->{channel};

	$redir = [ [$url, "Original"] ] unless defined $redir;

	# リダイレクトのチェック
	if (scalar(grep { $_->[0] eq $url } @$redir) > 1) {
		$self->notice_redir($redir);
		$channel->notice("\x034Error:\x03 Redirection Loop");
		return;
	} elsif (scalar(@$redir) > 10) {
		$self->notice_redir($redir);
		$channel->notice("\x034Error:\x03 Redirection Too Deep");
		return;
	}

	unless ($url =~ m!^((https?|ftp)://[^\!\$\<\>\"\'\{\}\|\\\^\[\]\`\x00-\x20\x7f-\xff]+)$!) {
		$self->notice_redir($redir);
		$channel->notice("\x034Error:\x03 Bad URL");
		return;
	}

	my $req = HTTP::Request->new("GET" , $url);
	my $res = $self->{ua}->request($req);

	if ($res->code() !~ /^2/) {
		my $location = $res->header("Location");
		if ($location) {
			push(@$redir, [$location, "HTTP " . $res->status_line()]);
			$self->do_request($location, $redir);
		} else {
			$self->notice_redir($redir);
			my $prefix = ($res->code() =~ /^[45]/) ? "\x034Error:\x03 " : "";
			$channel->notice($prefix . $res->status_line());
		}
		return;
	}

	$self->notice_redir($redir);

	if (!$res->content_type) {
		$channel->notice("\x034Error:\x03 Content-Type Undefined");
	} elsif ($res->content_type !~ m|text/x?html|) {
		$channel->notice($res->content_type);
	} else {
		my @ct = $res->header("Content-Type"); # HTML 中の <meta http-equiv="Content-Type"> も一緒に返ってくる。
		my @charsets = map { s/^charset=//i; $_; } grep(/^charset=/i, map { split(/[;\s]+/, $_); } @ct);
		my $charset = $charsets[0];

		if (!defined($charset)) {
			my $enc = guess_encoding($res->content(), @encoding_suspects);
			if (ref($enc)) {
				$charset = $enc->name();
			} else {
				$charset = "latin-1"; # guess 失敗。仕方ないので latin-1 にする。
			}
		}

		my $enc = Encode::find_encoding($charset);
		unless (ref($enc)) {
			$channel->notice("\x034Error:\x03 Character Encoding Unknown");
			return;
		}
		my $content = $enc->decode($res->content);

		my $parser = HTML::HeadParser->new();

		$parser->parse($content);
		$parser->eof();

		$channel->notice($parser->header("title"), "(Untitled Document)");
		if ($url =~ m|^http://www.nicovideo.jp/watch/|) {
			$channel->notice("登録タグ: " . scalar($parser->header("X-Meta-Keywords")));
			$channel->notice("説明文: " . scalar($parser->header("X-Meta-Description")));
		}
	}
}

sub notice_redir {
	my($self, $redir) = @_;

	if (scalar(@$redir) > 1) {
		$self->{channel}->notice($redir->[0]->[0]);
		for (my $i = 1; $i < scalar(@$redir); $i++) {
			my($location, $reason) = @{$redir->[$i]};
			$self->{channel}->notice(sprintf("%s> %s (%s)", "-" x $i, $location, $reason));
		}
	}
}

###############################################################################

return 1;
