# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::ImasUploaderPolling;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);

my $poller;

sub initialize {
	my($self) = @_;

	$poller = KotoriBot::Plugin::ImasUploaderPolling::Poller->new() unless defined($poller);
	$poller->add($self);
}

sub destroy {
	my($self) = @_;

	$poller->remove($self);
}

sub notice {
	my($self, $message) = @_;

	$self->{channel}->notice($message);
}

###############################################################################

package KotoriBot::Plugin::ImasUploaderPolling::Poller;

use strict;
use warnings;
use utf8;

use HTML::TokeParser;
use POE;

my $listurl = "http://imas.ath.cx/~imas/cgi-bin/pages.html";
my $baseurl = "http://imas.ath.cx/~imas/cgi-bin/src/";
my $first_delay = 30;
my $next_delay = 300;

sub new {
	my($class) = @_;

	my $self = bless({
		plugins => [],
		last => undef,
	}, $class);

	my $ua = LWP::UserAgent->new();
	$ua->timeout(5);
	$ua->max_redirect(0);
	$ua->agent("Kotori/" . KotoriBot::Core->version());
	$self->{ua} = $ua;

	my $session = POE::Session->create(
		object_states => [
			$self => [ qw(_start do_request) ],
		],
		heap => {}
	);
	$self->{session} = $session;

	return $self;
}

sub _start {
	my($self) = @_;

	POE::Kernel->delay("do_request", $first_delay);
}

sub do_request {
	my($self) = @_;

	my @files = ();

	my $req = HTTP::Request->new("GET", $listurl);
	$req->referer($listurl);
	my $res = $self->{ua}->request($req);

	if ($res->is_success) {
		my $content = Encode::decode("shift_jis", $res->content);

		# ものすごく汚いパーサ
		my $parser = HTML::TokeParser->new(\$content);
		while (my $token = $parser->get_tag("table")) {
			last if ($token->[1]->{summary} eq "upinfo");
		}
		while (my $token = $parser->get_tag("/table", "tr")) {
			last if ($token->[0] eq "/table");
			$token = $parser->get_tag("a");
			my $href = $token->[1]->{href};
			my %file;
			next unless ($href =~ /\.\/src\/(imas\d+\.[^\.]+)$/);
			$file{name} = $1;
			$parser->get_tag("td");
			$file{comment} = $parser->get_text();
			$parser->get_tag("td");
			$parser->get_text() =~ /(.*)B$/;
			$file{size} = $1;
			$parser->get_tag("td");
			$parser->get_tag("td");
			$parser->get_tag("td");
			$file{origname} = $parser->get_text();
			push(@files, \%file);
		}

		$self->done_request(\@files);
	} else {
		$self->done_request(undef);
	}
}

sub done_request {
	my($self, $f) = @_;

	if (defined($f)) {
		if (defined($self->{last})) {
			my @files = reverse(@$f);

			foreach my $file (@files) {
				$file->{name} =~ /\d+/;
				my $num = $&;
				if ($num > $self->{last}) {
					my $comment = ($file->{comment} !~ /^\s*$/) ? "\"$file->{comment}\"" : "(no comment)";
					my $origname = ($file->{origname} !~ /^\s*$/) ? $file->{origname} : "unknown";
					$self->notice(sprintf("ImasUploader: $baseurl%s %s, %sbytes (original: %s)", $file->{name}, $comment, $file->{size}, $origname));
				}
			}
		}
		$f->[0]->{name} =~ /\d+/;
		$self->{last} = $&;
	}

	POE::Kernel->delay("do_request", $next_delay);
}

sub add {
	my($self, $plugin) = @_;

	push(@{$self->{plugins}}, $plugin);
}

sub remove {
	my($self, $plugin) = @_;

	@{$self->{plugins}} = grep { $_ != $plugin } @{$self->{plugins}};
}

sub notice {
	my($self, $message) = @_;

	foreach my $plugin (@{$self->{plugins}}) {
		$plugin->notice($message);
	}
}

###############################################################################

return 1;
