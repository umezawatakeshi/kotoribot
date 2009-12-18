# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$
#
# Encode::JP::ExtJIS と Encode::JP::MSJIS を自動で読み込む
#

package Encode::ConfigLocal;

use strict;
use warnings;
use utf8;

use Encode::JP::ExtJIS;
use Encode::JP::MSJIS;

return 1;
