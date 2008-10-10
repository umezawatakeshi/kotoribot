#!/usr/bin/perl
# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

use strict;
use warnings;
use utf8;

use KotoriBot::Core;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $conffile;

if ($ARGV[0]) {
	$conffile = $ARGV[0];
} else {
	$conffile = "./kotoribot.conf";
}

our $conf;
require $conffile;

KotoriBot::Core->spawn($conf);

POE::Kernel->run();

exit(0);
