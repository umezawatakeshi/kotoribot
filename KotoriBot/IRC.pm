# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::IRC;

use strict;
use warnings;
use utf8;

use Encode;
use POE qw(Component::IRC::State);

our @ISA = qw(POE::Component::IRC::State);

###############################################################################

return 1;
