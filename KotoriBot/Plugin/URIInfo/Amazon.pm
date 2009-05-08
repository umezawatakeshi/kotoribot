# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::Amazon;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $match = qr/(asin):(\S+)/i;

sub initialize {
	my($self) = @_;
	my $channel = $self->{channel};

	my $uriinfo = $channel->plugin("KotoriBot::Plugin::URIInfo");
	if ($uriinfo) {
		$uriinfo->add_transform_plugin($self, $match);
	}
}

sub transform_uri {
	my($self, $context, $uri) = @_;

	$uri =~ $match;

	if ($1 eq "asin") {
		$context->process_redirect("http://www.amazon.co.jp/dp/$2");
	}
}

###############################################################################

return 1;
