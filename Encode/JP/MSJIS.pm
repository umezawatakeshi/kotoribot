# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$
#
# マイクロソフトの変換表に基づいた文字エンコーディング
#

package Encode::JP::MSJIS;

use strict;
use warnings;
use utf8;

use base qw(Encode::Encoding);

use Jcode;
use Jcode::CP932;

__PACKAGE__->Define(qw(ms-jis));
__PACKAGE__->Define(qw(ms-euc));
__PACKAGE__->Define(qw(ms-sjis));

sub encode {
	my($self, $str, $chk) = @_;
	my $name = $self->name();
	$name =~ s/^ms-//;

	my $fb = Jcode::CP932->new(Encode::encode("utf8", $str, $chk), "utf8")->fallback($chk);

	if ($name eq "jis") {
		return $fb->jis;
	} elsif ($name eq "euc") {
		return $fb->euc;
	} elsif ($name eq "sjis") {
		return $fb->sjis;
	} else {
		die;
	}
}

sub decode {
	my($self, $str, $chk) = @_;
	my $name = $self->name();
	$name =~ s/^ms-//;

	return Jcode::CP932->new($str, $name)->get;
}

return 1;
