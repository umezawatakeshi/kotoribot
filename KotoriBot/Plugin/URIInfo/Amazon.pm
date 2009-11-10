# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::Amazon;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin::URIInfo::HTTP);

my $asinmatch = qr/(asin):\s*(\S+)/i;

my $httpurlmatch = qr!https?://www\.amazon\..+?/[\#\%\&\(\)\*\+\,\-\.\/0-9\:\;\=\?\@A-Z\_a-z\~]*!;

sub new {
	my($class, $channel) = @_;

	my $self = $class->SUPER::new($channel);
	$self->{ua}->max_size(128 * 1024); # 128KB

	return $self;
}

sub initialize {
	my($self) = @_;
	my $channel = $self->{channel};

	my $uriinfo = $channel->plugin("KotoriBot::Plugin::URIInfo");
	if ($uriinfo) {
		$uriinfo->add_transform_plugin($self, $asinmatch);
		$uriinfo->add_transform_plugin($self, $httpurlmatch);
	}
}

sub transform_uri {
	my($self, $context, $uri) = @_;

	if ($uri =~ $asinmatch) {
		if ($1 eq "asin") {
			$context->process_redirect("http://www.amazon.co.jp/dp/$2");
		}
	} elsif ($uri =~ $httpurlmatch) {
		$self->SUPER::transform_uri($context, $uri);
	}
}

###############################################################################

return 1;
