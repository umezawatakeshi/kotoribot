# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Server;

use strict;
use warnings;
use utf8;

use Encode;
use POE qw(Component::IRC);

use KotoriBot::IRC;
use KotoriBot::Channel;

sub new($) {
	my($class, $hash) = @_;

	my $ircclass;
	if (exists($hash->{ircclass})) {
		$ircclass = $hash->{ircclass};
	} else {
		$ircclass = "KotoriBot::IRC";
	}

	eval "require $ircclass"; if ($@) { die $@; }
	my $irc = $ircclass->spawn();

	my $self = bless({
		hash => $hash,
		irc => $irc,
		channels => {},         # チャンネル名 => KotoriBot::Channel オブジェクト
		channelname_map => {},  # エンコードされたチャンネル名 => デコードされたチャンネル名
	}, $class);

	POE::Session->create(
		object_states => [
			$self => [ qw(
				_default _start irc_001 irc_disconnected irc_socketerr reconnect tick
				irc_pong irc_352 irc_353
				irc_join irc_part irc_kick irc_quit irc_invite
				irc_public irc_notice
				irc_ctcp_ping irc_ctcp_version
			) ],
		],
		heap => {}
	);

	$self->{hash}->{pocoirc_plugins} = [] unless exists $self->{hash}->{pocoirc_plugins};
	foreach my $plugindesc (@{$self->{hash}->{pocoirc_plugins}}) {
		my $pluginname;
		my $pluginalias;
		my @pluginargs;
		if (ref($plugindesc) eq "ARRAY") {
			my @plugindesc = @$plugindesc;
			$pluginname  = shift(@plugindesc);
			$pluginalias = shift(@plugindesc);
			$pluginalias = $pluginname unless defined($pluginalias);
			@pluginargs  = @plugindesc;
		} else {
			$pluginname  = $plugindesc;
			$pluginalias = $pluginname;
			@pluginargs  = ();
		}
		eval "require $pluginname"; if ($@) { die $@; }
		my $plugin = $pluginname->new(@pluginargs);
		print STDERR "\n$pluginalias\n\n";
		$irc->plugin_add($pluginalias, $plugin);
	}

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

	shift;
	$self->tick(@_);
}

sub irc_connected {
}

sub join_channel {
	my($self, $channelname, $password) = @_;
	my $irc = $self->{irc};

	my $channelhash;
	foreach my $ch (@{$self->{hash}->{channels}}) {
		if ($channelname eq $ch->{name}) {
			$channelhash = $ch;
			last;
		}
	}
	$channelhash = $self->{hash}->{default_channel};

	my @args = (Encode::encode($channelhash->{encoding}, $channelname));
	if (defined($password)) {
		push(@args, Encode::encode($channelhash->{encoding}, $password));
	} elsif ($channelhash && $channelhash->{password}) {
		push(@args, Encode::encode($channelhash->{encoding}, $channelhash->{password}));
	}
	$irc->yield("join", @args);
}

sub join_channel_encoded {
	my($self, $channelname_encoded, $require_config) = @_;
	my $irc = $self->{irc};

	my $channelhash;
	foreach my $ch (@{$self->{hash}->{channels}}) {
		if ($channelname_encoded eq Encode::encode($ch->{encoding}, $ch->{name})) {
			$channelhash = $ch;
			last;
		}
	}

	return if (!defined($channelhash) && $require_config);

	my @args = ($channelname_encoded);
	push(@args, Encode::encode($channelhash->{encoding}, $channelhash->{password})) if ($channelhash && $channelhash->{password});
	$irc->yield("join", @args);
}

sub tick {
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	if ($irc->connected()) {
		$self->{noresp}++;
		if ($self->{noresp} > 6) {
			print STDERR "server not responding\n";
			$irc->disconnect();
		} else {
			if (defined($irc->server_name())) {
				$irc->yield("ping", $irc->server_name());
			} else {
				print STDERR "not pinging... IRC-level handshake is not completed\n";
			}
		}
	}

	POE::Kernel->delay("tick", 30);
}

sub irc_pong {
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	$self->{noresp} = 0;
}

# 352 RPL_WHOREPLY
sub irc_352 {
	irc_pong(@_);
}

# 353 RPL_NAMREPLY
sub irc_353 {
	irc_pong(@_);
}

sub irc_001 {
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	$self->{noresp} = 0;

	foreach my $channelhash (@{$self->{hash}->{channels}}) {
		my $channelname = $channelhash->{name};
		my $channelname_encoded = Encode::encode($channelhash->{encoding}, $channelname);
		$self->{channelname_map}->{$channelname_encoded} = $channelname;
		$self->join_channel_encoded($channelname_encoded);
	}
}

sub irc_disconnected {
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	print STDERR "$self irc_disconnected\n";

	$self->cleanup_channels();

	$_[KERNEL]->delay("reconnect", 10);
}

sub irc_socketerr {
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	print "$self irc_socketerr\n";

	$self->cleanup_channels();

	if ($irc->connected()) {
		$irc->disconnect();
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
	} else {
		my $channel = $self->{channels}->{$self->{channelname_map}->{$channelname_encoded}};
		$channel->on_join($who);
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
	} else {
		$channel->on_part($who, $message_encoded);
	}
}

sub irc_kick {
	my($kicker_who, $channelname_encoded, $kickee_nick, $message_encoded, $kickee_who) = @_[ARG0, ARG1, ARG2, ARG3, ARG4];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	my $channel = $self->{channels}->{$self->{channelname_map}->{$channelname_encoded}};

	if ($kickee_nick eq $irc->nick_name()) {
		$channel->on_my_kick($kicker_who, $message_encoded);
		$channel->destroy();
		delete($self->{channels}->{$self->{channelname_map}->{$channelname_encoded}});
	} else {
		$channel->on_kick($kicker_who, $kickee_who, $message_encoded);
	}
}

sub irc_quit {
	my($who, $message_encoded, $channelnames_encoded) = @_[ARG0, ARG1, ARG2];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	my $nick = (split(/!/, $who))[0];

	if ($nick eq $irc->nick_name()) {
		$self->cleanup_channels();
	} else {
		foreach my $channelname_encoded (@$channelnames_encoded) {
			my $channel = $self->{channels}->{$self->{channelname_map}->{$channelname_encoded}};
			$channel->on_quit($who, $message_encoded);
		}
	}
}

sub cleanup_channels {
	my($self) = @_;

	foreach my $channel (values(%{$self->{channels}})) {
		$channel->on_my_quit();
		$channel->destroy();
	}
	$self->{channels} = {};
}

sub irc_invite {
	my($who, $channelname_encoded) = @_[ARG0, ARG1];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	if ($self->{hash}->{accept_invite}) {
		$self->join_channel_encoded($channelname_encoded, $self->{hash}->{accept_invite} != 1);
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

sub irc_notice {
	my($who, $channelnames_encoded, $message_encoded) = @_[ARG0, ARG1, ARG2];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	foreach my $channelname_encoded (@$channelnames_encoded) {
		my $channelname = $self->{channelname_map}->{$channelname_encoded};
		next unless $channelname;
		$self->{channels}->{$channelname}->on_notice($who, $message_encoded);
	}
}

sub irc_ctcp_ping {
	my($who, $arg1, $arg2) = @_[ARG0, ARG1, ARG2];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	$irc->yield("ctcpreply", $who, "ping", $arg2);
}

sub irc_ctcp_version {
	my($who, $arg1, $arg2) = @_[ARG0, ARG1, ARG2];
	my $self = $_[OBJECT];
	my $irc = $self->{irc};

	$irc->yield("ctcpreply", $who, "version", KotoriBot::Core->longversion());
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
