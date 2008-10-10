# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Channel;

use strict;
use warnings;
use utf8;

use Encode;
use POE qw(Component::IRC);

sub new($$$$) {
	my($class, $server, $hash, $channelname, $channelname_encoded) = @_;

	my $self = bless({
		server => $server,
		hash => $hash,
		name => $channelname,
		name_encoded => $channelname_encoded,
		plugins => [], # プラグインのオブジェクトのリスト
	}, $class);

	foreach my $pluginname (@{$self->{hash}->{plugins}}) {
		eval "require $pluginname"; if ($@) { die $@; }
		push(@{$self->{plugins}}, $pluginname->new($self));
	}

	return $self;
}

###############################################################################
#### KotoriBot::Server から呼ばれるイベントハンドラ

sub initialize() {
	my($self) = @_;

	foreach my $plugin (@{$self->{plugins}}) {
		$plugin->initialize();
	}
}

sub destroy() {
	my($self) = @_;

	foreach my $plugin (@{$self->{plugins}}) {
		$plugin->destroy();
	}

	$self->{plugins} = [];
}

sub on_my_join() {
	my($self) = @_;

	foreach my $plugin (@{$self->{plugins}}) {
		$plugin->on_my_join();
	}
	$self->notice("Hello, this is KotoriBot.") unless $self->{suppress_introduce};
}

sub on_my_part() {
	my($self) = @_;

	foreach my $plugin (@{$self->{plugins}}) {
		$plugin->on_my_part();
	}
}

sub on_my_kick($$) {
	my($self, $who, $message_encoded) = @_;

	my $message = Encode::decode($self->{hash}->{encoding}, $message_encoded);

	foreach my $plugin (@{$self->{plugins}}) {
		$plugin->on_my_kick($who, $message);
	}

	if ($self->{hash}->{persist}) {
		$self->{server}->do_join($self->{name_encoded});
	}
}

sub on_public($$) {
	my($self, $who, $message_encoded) = @_;

	my $message = Encode::decode($self->{hash}->{encoding}, $message_encoded);

	foreach my $plugin (@{$self->{plugins}}) {
		$plugin->on_public($who, $message);
	}
}

###############################################################################
#### 各種オブジェクトメソッド

# このチャンネルが属しているサーバを返す。
# 返り値は KotoriBot::Server のオブジェクトである。
sub server() {
	my($self) = @_;

	return $self->{server};
}

# このチャンネルに notice でメッセージを送信する。
# 引数は UTF-8 フラグ付き文字列である。
# 1つ目の引数が undef もしくは空文字列の場合は、2つ目の引数を送信する。
# 2つ目の引数も undef もしくは空文字列の場合は、何もしない。
# 返り値は不定である。
sub notice($;$) {
	my($self, $message, $altmessage) = @_;

	if (!defined($message) || $message eq "") {
		$message = $altmessage;
	}
	return if (!defined($message) || $message eq "");

	$self->{server}->irc()->yield(
		"notice",
		$self->{name_encoded},
		Encode::encode($self->{hash}->{encoding}, $message, Encode::FB_PERLQQ)
	);
}

# このチャンネルから退出する。
# 返り値は不定である。
sub part() {
	my($self) = @_;

	$self->{server}->irc()->yield("part", $self->{name_encoded});
}

# このチャンネルに関連付けられているプラグインオブジェクトのリストを返す。
# 返り値は KotoriBot::Plugin（のサブクラス）のオブジェクトのリストである。
sub plugins() {
	my($self) = @_;

	return @{$self->{plugins}};
}

# KotoriBot::Channel オブジェクト自身による自己紹介を抑制する。
# 独自の自己紹介を行うプラグインから呼び出すことを意図している。
# 返り値は不定である。
sub suppress_introduce() {
	my($self) = @_;

	$self->{suppress_introduce} = 1;
}

###############################################################################

return 1;
