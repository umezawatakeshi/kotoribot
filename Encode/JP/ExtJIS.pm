# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$
#
# JIS の範囲に対応する文字が存在しない Unicode 文字（主に記号）を、
# グリフが似た JIS 文字列に置き換える文字エンコーディング
#

package Encode::JP::ExtJIS;

use strict;
use warnings;
use utf8;

use base qw(Encode::Encoding);

__PACKAGE__->Define(qw(ext-iso-2022-jp));
__PACKAGE__->Define(qw(ext-euc-jp));
__PACKAGE__->Define(qw(ext-shiftjis));
__PACKAGE__->Define(qw(ext-cp932));

__PACKAGE__->Define(qw(ext-ms-jis));
__PACKAGE__->Define(qw(ext-ms-euc));
__PACKAGE__->Define(qw(ext-ms-sjis));

sub encode {
	my($self, $str, $chk) = @_;
	my $name = $self->name();
	$name =~ s/^ext-//;

	# JISの範囲にない文字を、似た文字で置き換える。
	$str =~ tr
		[\x{ff5e}\x{00ab}\x{00bb}\x{00b7}\x{00a0}\x{ff0d}]
		[\x{301c}\x{226a}\x{226b}\x{30fb}\x{0020}\x{002d}];

	# 置き換え元
	# \x{ff5e} = ～
	# \x{00ab} = «
	# \x{00bb} = »
	# \x{00b7} = ·（半角ラテン中点）
	# \x{00a0} =  （\x{0020}とは別の空白）
	# \x{ff0d} = －

	# 置き換え先
	# \x{301c} = 〜
	# \x{226a} = ≪
	# \x{226b} = ≫
	# \x{30fb} = ・
	# \x{0020} =  
	# \x{002d} = -

	# \x{301c} と \x{ff5e} は両方とも「波」の形をした文字であるが、
	# Windows XP 以前のフォントだと波の向きが逆になっている。
	# Windows Vista 以降のフォントだと向きは同じである。

	# 適切な置き換え文字が無いものは、複数文字で置き換える。
	$str =~ s/\x{00a9}/\(c\)/g;  # \x{00a9} = ©（著作権表示文字）;
	$str =~ s/\x{00ae}/\(R\)/g;  # \x{00ae} = ®（登録商標文字）;
	$str =~ s/\x{2120}/\(SM\)/g; # \x{2120} = ℠（上付きサービスマーク文字）
	$str =~ s/\x{2122}/\(TM\)/g; # \x{2122} = ™（上付き商標文字）

	# 変換時に消滅すべき文字
	# $str =~ s/\x{fffe}//g; # \x{fffe} は Unicode 文字としては不正らしい
	$str =~ s/[\x{feff}\x{200b}]//g;

	return Encode::encode($name, $str, $chk);
}

sub decode {
	my($self, $str, $chk) = @_;
	my $name = $self->name();
	$name =~ s/^ext-//;
	return Encode::decode($name, $str, $chk);
}

return 1;
