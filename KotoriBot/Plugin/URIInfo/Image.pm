# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id: HTML.pm 25 2008-10-17 14:00:43Z umezawa $

package KotoriBot::Plugin::URIInfo::Image;

use strict;
use warnings;
use utf8;

use Image::ExifTool;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub initialize {
	my($self) = @_;

	my $uriinfo = $self->{channel}->plugin("KotoriBot::Plugin::URIInfo");
	if ($uriinfo) {
		$uriinfo->add_output_plugin($self, qr/.*/, qr!image/.*!);
	}
}

sub output_content {
	my($self, $context, $content, $ct) = @_;

	my $info = Image::ExifTool::ImageInfo(\$content);
#	{
#		use KotoriBot::Core;
#		KotoriBot::Core::rec_print($info, '$info');
#	}

	$context->notice_redirects();
	$context->notice("$info->{FileType} image, $info->{ImageSize}");
}

###############################################################################

return 1;
