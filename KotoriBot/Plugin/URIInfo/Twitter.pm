# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::Twitter;

use strict;
use warnings;
use utf8;

use HTTP::Request::Common;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $hashtweetmatch = qr!http://twitter\.com/\#\x21/([^/]+/status/\d+)!;

sub initialize {
	my($self) = @_;
	my $channel = $self->{channel};

	my $uriinfo = $channel->plugin("KotoriBot::Plugin::URIInfo");
	if ($uriinfo) {
		$uriinfo->add_transform_plugin($self, $hashtweetmatch);
	}

	my $http = $channel->plugin("KotoriBot::Plugin::URIInfo::HTTP");
	$self->{http} = $http;
}

sub transform_uri {
	my($self, $context, $uri) = @_;

	if ($uri =~ /$hashtweetmatch/) {
		my $req = HTTP::Request::Common::GET("http://twitter.com/$1");
		$self->{http}->do_request($context, $req);
	} else {
		$self->{http}->transform_uri($context, $uri);
	}
}

###############################################################################

return 1;
