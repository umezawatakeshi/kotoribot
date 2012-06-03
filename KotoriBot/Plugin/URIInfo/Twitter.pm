# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::Twitter;

use strict;
use warnings;
use utf8;

use JSON qw(decode_json);

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $hashurlmatch = qr!https?://twitter\.com/\#\x21/([a-zA-z0-9_]+(?:/status/\d+(?:/photo/\d+)?)?)!;
my $statusmatch = qr!https?://twitter\.com/[a-zA-z0-9_]+/status/(\d+)(?:/photo/\d+)?!;
my $statusapijsonmatch = qr!https?://api\.twitter\.com/1/statuses/show/\d+\.json!;

sub initialize {
	my($self) = @_;
	my $channel = $self->{channel};

	my $uriinfo = $channel->plugin("KotoriBot::Plugin::URIInfo");
	if ($uriinfo) {
		$uriinfo->add_transform_plugin($self, $hashurlmatch);
		$uriinfo->add_transform_plugin($self, $statusmatch);
		$uriinfo->add_output_plugin($self, $statusapijsonmatch, qr!application/json!);
	}
}

sub transform_uri {
	my($self, $context, $uri) = @_;

	if ($uri =~ /$hashurlmatch/) {
		$context->process_redirect("http://twitter.com/$1", undef, 1);
	} elsif ($uri =~ /$statusmatch/) {
		$context->process_redirect("http://api.twitter.com/1/statuses/show/$1.json", undef, 1);
	} else {
		$context->process_error(ref($self).": Unexpected Transformation Request");
	}
}

sub output_content {
	my($self, $context, $content, $ct, $clen, $uri) = @_;

	my $doc = decode_json($content);

	my $username = $doc->{user}{name};
	my $text = $doc->{text};

	$context->notice_redirects();
	$context->notice("Twitter / $username: $text");
}

###############################################################################

return 1;
