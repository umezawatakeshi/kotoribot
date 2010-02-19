# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Core;

require v5.8.0;

use strict;
use warnings;
use utf8;

use Digest::MD5 qw(md5_hex);

use KotoriBot::Server;

sub rec_print($$);
sub expand_serverhash($);

my $instanceid = md5_hex(time() . " " . `uname -a`); # /dev/urandom も読むべきか。
my @servers;

sub version { return "1.17.0"; }
sub longversion { return "KotoriBot " . version(); }
sub agent { return "KotoriBot/" . version(); }
sub instanceid { return $instanceid; }

sub servers { return @servers; }

sub spawn {
	my($class, $conf) = @_;

	foreach my $serverhash (@{$conf->{servers}}) {
		#rec_print($serverhash, '$sh');print"\n";
		expand_serverhash($serverhash);
		#rec_print($serverhash, '$sh');print"\n\n";
		my $server = KotoriBot::Server->new($serverhash);
		push(@servers, $server);
	}
}

sub rec_print($$) {
	my($val, $var) = @_;

	print "$var = $val\n";
	if (ref($val) eq "ARRAY") {
		my $n = scalar(@$val);
		for (my $i = 0; $i < $n; $i++) {
			rec_print($val->[$i], $var."->[$i]");
		}
	} elsif (ref($val) eq "HASH") {
		my @ks = keys(%$val);
		foreach my $k (@ks) {
			rec_print($val->{$k}, $var."->{$k}");
		}
	}
}

sub expand_serverhash($) {
	my($sh) = @_;

	$sh->{channels} = [] unless exists $sh->{channels};
	my $dch = $sh->{default_channel};
	foreach my $ch (@{$sh->{channels}}) {
		if (ref($ch) eq "") {
			# $ch が単なる文字列だった場合、チャンネル名として扱う。
			$ch = { name => $ch }; # $ch を変更すると @{$sh->{channels}} の中身が変わる
		}
		set_default($ch, $dch, "persist");
		set_default($ch, $dch, "encoding");
		set_default($ch, $dch, "lang");
		merge_array($ch, $dch, "plugins");
		$ch->{persist} = 1 unless exists $ch->{persist};
	}
}

sub set_default($$$) {
	my($h1, $h2, $k) = @_;

	$h1->{$k} = $h2->{$k} unless exists $h1->{$k};
}

sub merge_array($$$) {
	my($h1, $h2, $k) = @_;

	my @ht;
	my @hn;
	my @hy;

	@ht = @{$h2->{$k}} if exists $h2->{$k};
	@hn = @{$h1->{"no$k"}} if exists $h1->{"no$k"};
	@hy = @{$h1->{$k}} if exists $h1->{$k};

	@ht = grep { my $e = $_; scalar(grep { $_ eq $e } @hn) == 0; } @ht;

	@ht = grep { my $e = $_; scalar(grep { $_ eq $e } @hy) == 0; } @ht;
	push(@ht, @hy);

	$h1->{$k} = \@ht;
	delete $h1->{"no$k"};
}

###############################################################################

return 1;
