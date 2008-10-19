# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

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
	my($self, $context, $content, $ct, $clen) = @_;

	my $info = Image::ExifTool::ImageInfo(\$content);
#	{
#		use KotoriBot::Core;
#		KotoriBot::Core::rec_print($info, '$info');
#	}

	$context->notice_redirects();
	if (defined($clen)) {
		$clen =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/g;
		$clen = ", $clen" . "bytes";
	} else {
		$clen = "";
	}
	$context->notice("$info->{FileType} image, $info->{ImageSize}$clen");
}

###############################################################################

return 1;
