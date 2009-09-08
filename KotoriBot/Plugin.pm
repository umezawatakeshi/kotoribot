# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin;

use strict;
use warnings;
use utf8;

sub new {
	my($class, $channel) = @_;

	return bless({
		channel => $channel,
	}, $class);
}

###############################################################################
#### KotoriBot::Channel から呼ばれるイベントハンドラ

# プラグインを初期化する。
# 他のプラグインは既に生成されていることが保証されている。
sub initialize() {}

# プラグインを破棄する
sub destroy() {}


# 自分がチャンネルに参加した。
sub on_my_join() {}

# 自分がチャンネルから退出した。
sub on_my_part() {}

# 自分がチャンネルで蹴られた。
sub on_my_kick($$) {}

# 自分がサーバから切断した結果としてチャンネルから退出した。
sub on_my_quit {}


# 他人がチャンネルに参加した。
sub on_join {}

# 他人がチャンネルから退出した。
sub on_part {}

# 他人がチャンネルで蹴られた。
sub on_kick {}

# 他人がサーバから切断した結果としてチャンネルから退出した。
sub on_quit {}


# チャンネルの発言を受信した。
sub on_public($$) {}

# チャンネルのnoticeを受信した。
sub on_notice($$) {}


# PluginHelp プラグインで使われるヘルプ文字列を返す。
sub helpstring { return undef; }

###############################################################################

return 1;
