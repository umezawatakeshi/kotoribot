# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::IRC;

use strict;
use warnings;
use utf8;

use Encode;
use POE qw(Component::IRC);

our @ISA = qw(POE::Component::IRC);

###############################################################################

return 1;
