# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Server;

use strict;
use warnings;
use utf8;

use Encode;
use POE qw(Component::IRC);

use KotoriBot::Channel;

sub new($) {
	my($class, $hash) = @_;

	my $irc = POE::Component::IRC->spawn();

	my $self = bless({
		hash => $hash,
		irc => $irc,
		channels => {},         # チャンネル名 => KotoriBot::Channel オブジェクト
		channelname_map => {},  # エンコードされたチャンネル名 => デコードされたチャンネル名
	}, $class);

	POE::Session->create(
		object_states => [
			$self => [ qw(_default _start irc_001 irc_disconnected irc_socketerr reconnect irc_join irc_kick irc_invite irc_public) ],
		],
		heap => {}
	);

	return $self;
}

###############################################################################
#### POE::Component::IRC イベントハンドラ

#	my($object, $session, $kernel, $heap, $state, $sender) =
#		@_[OBJECT, SESSION, KERNEL, HEAP, STATE, SENDER];

sub _start {
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	$irc->yield("register", "all");
	$irc->yield("connect", $self->{hash}->{connect});
}

sub irc_connected {
}

sub do_join($) {
	my($self, $channelname_encoded) = @_;
	my $irc = $self->{irc};

	my $channelhash;
	foreach my $ch (@{$self->{hash}->{channels}}) {
		if ($channelname_encoded eq Encode::encode($ch->{encoding}, $ch->{name})) {
			$channelhash = $ch;
			last;
		}
	}

	my @args = ($channelname_encoded);
	push(@args, $channelhash->{password}) if ($channelhash && $channelhash->{password});
	$irc->yield("join", @args);
}

sub irc_001 {
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	foreach my $channelhash (@{$self->{hash}->{channels}}) {
		my $channelname = $channelhash->{name};
		my $channelname_encoded = Encode::encode($channelhash->{encoding}, $channelname);
		$self->{channelname_map}->{$channelname_encoded} = $channelname;
		$self->do_join($channelname_encoded);
	}
}

sub irc_disconnected {
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	print STDERR "$self irc_disconnected\n";

	$_[KERNEL]->delay("reconnect", 10);
}

sub irc_socketerr {
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	print "$self irc_socketerr\n";
	if ($irc->connected()) {
		$irc->yield("disconnect");
	} else {
		$_[KERNEL]->delay("reconnect", 10);
	}
}

sub reconnect {
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	print "$self reconnect\n";
	$irc->yield("connect", $self->{hash}->{connect});
}

sub irc_error {
	#my($message) = @_[ARG0];
	my $message = $_[ARG0];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};
}

sub irc_join {
	my($who, $channelname_encoded) = @_[ARG0, ARG1];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	my $nick = (split(/!/, $who))[0];

	if ($nick eq $irc->nick_name()) {
		my $channelhash;
		my $channelname;
		foreach my $ch (@{$self->{hash}->{channels}}) {
			if ($channelname_encoded eq Encode::encode($ch->{encoding}, $ch->{name})) {
				$channelhash = $ch;
				$channelname = $ch->{name};
				last;
			}
		}
		if (!$channelhash) {
			$channelhash = $self->{hash}->{default_channel};
			$channelname = Encode::decode($channelhash->{encoding}, $channelname_encoded);
			$self->{channelname_map}->{$channelname_encoded} = $channelname;
		}
		my $channel = KotoriBot::Channel->new(
			$self, $channelhash,
			$channelname,
			$channelname_encoded
		);
		$self->{channels}->{$channelname} = $channel;
		$channel->initialize();
		$channel->on_my_join();
	}
}

sub irc_part {
	my($who, $channelname_encoded, $message_encoded) = @_[ARG0, ARG1, ARG2];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	my $nick = (split(/!/, $who))[0];

	my $channel = $self->{channels}->{$self->{channelname_map}->{$channelname_encoded}};

	if ($nick eq $irc->nick_name()) {
		$channel->on_my_part();
		$channel->destroy();
		delete($self->{channels}->{$self->{channelname_map}->{$channelname_encoded}});
	}
}

sub irc_kick {
	my($who, $channelname_encoded, $kickee, $message_encoded) = @_[ARG0, ARG1, ARG2, ARG3];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	my $channel = $self->{channels}->{$self->{channelname_map}->{$channelname_encoded}};

	if ($kickee eq $irc->nick_name()) {
		$channel->on_my_kick($who, $message_encoded);
		$channel->destroy();
		delete($self->{channels}->{$self->{channelname_map}->{$channelname_encoded}});
	}
}

sub irc_invite {
	my($who, $channelname_encoded) = @_[ARG0, ARG1];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	if ($self->{hash}->{accept_invite}) {
		$self->do_join($channelname_encoded);
	}
}

sub irc_public {
	my($who, $channelnames_encoded, $message_encoded) = @_[ARG0, ARG1, ARG2];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	foreach my $channelname_encoded (@$channelnames_encoded) {
		my $channelname = $self->{channelname_map}->{$channelname_encoded};
		next unless $channelname;
		$self->{channels}->{$channelname}->on_public($who, $message_encoded);
	}
}

sub _default {
	my ($event, $args) = @_[ARG0 .. $#_];
	my @output = ( $_[OBJECT], "$event: " );

	return if $event eq "irc_372";
	return if $event eq "irc_ping";
	return if $event eq "irc_notice";

	foreach my $arg ( @$args ) {
		if ( ref($arg) eq 'ARRAY' ) {
			push( @output, "[" . join(" ,", @$arg ) . "]" );
		} else {
			push ( @output, "'$arg'" );
		}
	}
	print STDOUT join ' ', @output, "\n";
}

###############################################################################
#### 各種オブジェクトメソッド

# 現在 join しているチャンネルのリストを返す。
# 返り値は KotoriBot::Channel のオブジェクトのリストである。
sub channels() {
	my($self) = @_;

	return values(%{$self->{channels}});
}

# 指定した名前のチャンネルを返す。
# 引数は UTF-8 フラグ付き文字列である。
# 返り値は KotoriBot::Channel のオブジェクトである。
# 指定したチャンネルに join していなかったら undef を返す。
sub channel($) {
	my($self, $channelname) = @_;

	return $self->{channels}->{$channelname};
}

# サーバの可読名を返す。
# 返り値は UTF-8 フラグ付き文字列である。
sub name() {
	my($self) = @_;

	return $self->{hash}->{name};
}

# サーバの irc オブジェクトを返す。
# 返り値は POE::Component::IRC のオブジェクトである。
sub irc() {
	my($self) = @_;

	return $self->{irc};
}

###############################################################################

return 1;
