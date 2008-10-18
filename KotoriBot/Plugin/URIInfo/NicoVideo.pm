# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::NicoVideo;

use strict;
use warnings;
use utf8;

use HTML::HeadParser;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub initialize {
	my($self) = @_;

	my $uriinfo = $self->{channel}->plugin("KotoriBot::Plugin::URIInfo");
	if ($uriinfo) {
		$uriinfo->add_output_plugin($self, qr!http://www\.nicovideo\.jp/watch/..\d+!, qr/.*/);
	}
}

sub output_content {
	my($self, $context, $content, $ct) = @_;

	my $parser = HTML::HeadParser->new();

	$parser->parse($content);
	$parser->eof();

	$context->notice_redirects();
	$context->notice($parser->header("title") . " (" . scalar($parser->header("X-Meta-Keywords")) . ")");
}

###############################################################################

return 1;
