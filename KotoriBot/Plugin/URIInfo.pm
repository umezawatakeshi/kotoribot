# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::URIInfo;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

sub new {
	my($class, $channel) = @_;

	my $self = bless(KotoriBot::Plugin->new($channel), $class);

	$self->{urimatch} = qr/.^/; # 絶対にマッチしない正規表現
	$self->{transforms} = [];
	$self->{outputs} = [];

	return $self;
}

sub on_public($$) {
	my($self, $who, $message) = @_;

	my $urimatch = $self->{urimatch};
	while ($message =~ /($urimatch)/g) {
		my $uri = $1;

		my $context = KotoriBot::Plugin::URIInfo::Context->new($self);
		$context->process_redirect($uri);
	}
}

sub add_transform_plugin {
	my($self, $transform, $urimatch) = @_;

	unshift(@{$self->{transforms}}, [$transform, $urimatch]);
	$self->{urimatch} = qr/$self->{urimatch}|$urimatch/;
}

sub lookup_transform_plugin {
	my($self, $uri) = @_;

	my $transforms = $self->{transforms};
	foreach my $transformtouple (@$transforms) {
		my($transform, $urimatch) = @$transformtouple;
		return $transform if ($uri =~ /^$urimatch$/)
	}
	return undef;
}

sub add_output_plugin {
	my($self, $output, $urimatch, $ctmatch) = @_;

	unshift(@{$self->{outputs}}, [$output, $urimatch, $ctmatch]);
}

sub lookup_output_plugin {
	my($self, $uri, $ct) = @_;

	my $outputs = $self->{outputs};
	foreach my $outputtouple (@$outputs) {
		my($output, $urimatch, $ctmatch) = @$outputtouple;
		return $output if ($uri =~ /^$urimatch$/ && $ct =~ /^$ctmatch$/)
	}
	return undef;
}

sub notice {
	my($self, $message, $altmessage) = @_;
	my $channel = $self->{channel};

	$channel->notice($message, $altmessage);
}

###############################################################################

package KotoriBot::Plugin::URIInfo::Context;

use strict;
use warnings;
use utf8;

sub new {
	my($class, $uriinfo) = @_;

	my $self = bless({
		uriinfo => $uriinfo,
		redirects => [],
	}, $class);

	return $self;
}

sub process_uri {
	my($self, $uri, $message) = @_;

	$self->process_redirect($uri, "Original");
}

sub process_redirect {
	my($self, $uri, $message) = @_;
	my $uriinfo = $self->{uriinfo};
	my $redirects = $self->{redirects};

	push(@$redirects, [ $uri, $message ]);

	if (scalar(grep { $_->[0] eq $uri } @$redirects) > 1 && !$self->{disable_loop_detection}) {
		$self->process_error("Redirection Loop");
		return;
	} elsif (scalar(@$redirects) > 10) {
		$self->process_error("Redirection Too Deep");
		return;
	}

	my $transform = $uriinfo->lookup_transform_plugin($uri);
	if (defined($transform)) {
		$transform->transform_uri($self, $uri);
	} else {
		$self->process_error("URI cannot be processed");
	}
}

sub process_content {
	my($self, $content, $ct, $clen) = @_;
	my $uriinfo = $self->{uriinfo};
	my $redirects = $self->{redirects};

	my $uri = $redirects->[scalar(@$redirects)-1]->[0];
	my $output = $uriinfo->lookup_output_plugin($uri, $ct);
	if (defined($output)) {
		$output->output_content($self, $content, $ct, $clen, $uri);
	} else {
		$self->notice_redirects();
		if (defined($clen)) {
			1 while $clen =~ s/(\d+)(\d\d\d)/$1,$2/;
			$clen = ", $clen" . "bytes";
		} else {
			$clen = "";
		}
		$self->notice("$ct$clen");
	}
}

sub process_error {
	my($self, $message) = @_;

	$self->notice_redirects();
	$self->notice("\x034Error:\x03 $message");
}

sub notice {
	my($self, $message, $altmessage) = @_;
	my $uriinfo = $self->{uriinfo};

	$uriinfo->notice($message, $altmessage);
}

sub notice_redirects {
	my($self) = @_;
	my $redirects = $self->{redirects};

	if (scalar(@$redirects) > 1) {
		$self->notice($redirects->[0]->[0]);
		for (my $i = 1; $i < scalar(@$redirects); $i++) {
			my($uri, $reason) = @{$redirects->[$i]};
			my $message = sprintf("%s> %s", "-" x $i, $uri);
			$message = "$message ($reason)" if defined($reason);
			$self->notice($message);
		}
	}
}

# web form による認証後に同じ URI に戻ってくる際に、ループ検出を無効にするために使う。
sub disable_loop_detection {
	my($self) = @_;

	$self->{disable_loop_detection} = 1;
}

###############################################################################

return 1;
