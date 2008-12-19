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


# チャンネルの発言を受信した。
sub on_public($$) {}


# PluginHelp プラグインで使われるヘルプ文字列を返す。
sub helpstring { return undef; }

###############################################################################

return 1;
