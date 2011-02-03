# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::Reverse;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub new {
	my($class, $channel) = @_;

	my $self = bless(KotoriBot::Plugin->new($channel), $class);

	return $self;
}

sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	if ($message =~ /^\s*reverse:\s*(.*?)\s*$/) {
		my $rev = reverse($1);
		$channel->notice($rev);
	}
}

###############################################################################

return 1;
