# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Core;

use strict;
use warnings;
use utf8;

use KotoriBot::Server;

sub rec_print($$);
sub expand_serverhash($);

sub version { return "1.4.0"; }

sub longversion { return "KotoriBot " . version(); }

sub agent { return "KotoriBot/" . version(); }

sub spawn {
	my($class, $conf) = @_;

	foreach my $serverhash (@{$conf->{servers}}) {
		#rec_print($serverhash, '$sh');print"\n";
		expand_serverhash($serverhash);
		#rec_print($serverhash, '$sh');print"\n\n";
		KotoriBot::Server->new($serverhash);
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
		$ch->{persist} = 1 unless exists $ch->{persist};
		set_default($ch, $dch, "encoding");
		merge_array($ch, $dch, "plugins");
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
