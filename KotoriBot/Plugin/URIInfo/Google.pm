# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::Google;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $match = qr/(google|feelinglucky):(\S+)/;

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

	if ($1 eq "feelinglucky") {
		$fladd = "&btnI=1";
	}

	$keyword = Encode::encode("utf-8", $2);
	$keyword =~ s/([^\w ])/'%'.unpack('H2', $1)/eg;
	$keyword =~ tr/ /+/;

	$context->process_redirect("http://www.google.com/search?hl=ja&ie=utf-8&oe=utf-8&q=$keyword$fladd");
}

###############################################################################

return 1;
