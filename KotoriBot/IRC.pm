# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::IRC;

use strict;
use warnings;
use utf8;

use Encode;
use POE qw(Component::IRC::State);

our @ISA = qw(POE::Component::IRC::State);

sub sl_prioritized {
	$_[ARG1] =~ s/[\x00\x0a\x0d]/sprintf('\x{%04x}',ord($&))/eg;

	my $self = shift;

	return $self->SUPER::sl_prioritized(@_);
}

###############################################################################

return 1;
