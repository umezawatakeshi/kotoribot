# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo::HTML;

use strict;
use warnings;
use utf8;

use HTML::TokeParser;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub initialize {
	my($self) = @_;

	my $uriinfo = $self->{channel}->plugin("KotoriBot::Plugin::URIInfo");
	if ($uriinfo) {
		$uriinfo->add_output_plugin($self, qr/.*/, qr!(?:text|application)/x?html(?:\+xml)?!);
	}
}

sub output_content {
	my($self, $context, $content, $ct) = @_;

	my $title = undef;
	my $parser = HTML::TokeParser->new(\$content);
	if  ($parser->get_tag("title")) {
		$title =  $parser->get_text();
		$title =~ s/[\r\n]/ /g;
		$title =~ s/^\s+//;
		$title =~ s/\s+$//;
		$title =~ s/\s+/ /g;
	}

	$context->notice_redirects();
	$context->notice($title, "(Untitled Document)");
}

###############################################################################

return 1;
