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
use POE qw(Component::Client::HTTP);

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

	$self->{ua_alias} = "$self-POE::Component::Client::HTTP";
	POE::Component::Client::HTTP->spawn(
		Alias => $self->{ua_alias},
		Agent => "Kotori/" . KotoriBot::Core->version(),
	);

	my $session = POE::Session->create(
		object_states => [
			$self => [ qw(_start do_request done_request) ],
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

	my $req = HTTP::Request->new("GET", $listurl);
	$req->referer($listurl);

	POE::Kernel->post($self->{ua_alias}, "request", "done_request", $req);
}

sub done_request {
	my($self, $reqp, $resp) = @_[OBJECT, ARG0, ARG1];

	my @files = ();
	my $res = $resp->[0];

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
	}

	if (scalar(@files) > 0) {
		@files = reverse(@files);
		if (defined($self->{last})) {
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
		$files[scalar(@files)-1]->{name} =~ /\d+/;
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
