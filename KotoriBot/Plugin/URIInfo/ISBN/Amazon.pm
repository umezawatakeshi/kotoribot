# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::ISBN::Amazon;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $match = qr/(isbn):(\S+)/i;

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

	my $keyword;
	my $fladd = "";

	$uri =~ $match;

	if ($1 eq "isbn") {
		$context->process_redirect("http://www.amazon.co.jp/dp/$2");
	}
}

###############################################################################

return 1;
