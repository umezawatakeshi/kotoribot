# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::ImasInfo;

use strict;
use warnings;
use utf8;

use KotoriBot::Plugin;

our @ISA = qw(KotoriBot::Plugin);


my $param_map = {
	"名字"         => 0,
	"苗字"         => 0,
	"名前"         => 2,
	"歳"           => 4,
	"年"           => 4,
	"年齢"         => 4,
	"身長"         => 5,
	"体重"         => 6,
	"誕生日"       => 7,
	"血液型"       => 8,
	"バスト"       => 9,
	"胸囲"         => 9,
	"乳"           => 9,
	"ウエスト"     => 10,
	"ウェスト"     => 10,
	"腰"           => 10,
	"ヒップ"       => 11,
	"尻"           => 11,
	"スリーサイズ" => 12,
	"趣味"         => 13,
};
my @param_names = (
	"名字", "family name", "名前", "given name",
	"年齢", "身長", "体重", "誕生日", "血液型",
	"バスト", "ウエスト", "ヒップ", "スリーサイズ",
	"趣味",
);

my $param_match;

$param_match = join("|", keys(%$param_map));
$param_match = qr/$param_match/i;


my $list = [
	# 名字      f-name       名前,     g-name,    歳 身長  重  誕生日       血   乳  腰  尻     3S  趣味
	[ "天海",   "amami",     "春香",   "haruka",  16, 158, 45, "4月3日",    "O", 83, 56, 80, undef, "おかし作り、カラオケ" ],
	[ "如月",   "kisaragi",  "千早",   "chihaya", 15, 162, 41, "2月25日",   "A", 72, 55, 78, undef, "音楽鑑賞（クラシック）" ],
	[ "萩原",   "hagiwara",  "雪歩",   "yukiho",  16, 154, 40, "12月24日",  "A", 80, 55, 81, undef, "MY詩集を書くこと、日本茶" ],
	[ "高槻",   "takatsuki", "やよい", "yayoi",   13, 145, 37, "3月25日",   "O", 72, 54, 77, undef, "オセロ" ],
	[ "秋月",   "akizuki",   "律子",   "ritsuko", 18, 156, 43, "6月23日",   "A", 85, 57, 85, undef, "資格取得、分析すること" ],
	[ "三浦",   "miura",     "あずさ", "azusa",   20, 168, 48, "7月19日",   "O", 91, 59, 86, undef, "犬の散歩" ],
	[ "水瀬",   "minase",    "伊織",   "iori",    14, 150, 39, "5月5日",   "AB", 77, 54, 79, undef, "海外旅行、ショッピング" ],
	[ "菊池",   "kikuchi",   "真",     "makoto",  16, 157, 42, "8月29日",   "O", 73, 56, 76, undef, "スポーツ全般" ],
	[ "双海",   "futami",    "亜美",   "ami",     12, 149, 39, "5月22日",   "B", 74, 53, 77, undef, "メール、モノマネ" ],
	[ "双海",   "futami",    "真美",   "mami",    12, 149, 39, "5月22日",   "B", 74, 53, 77, undef, "メール、モノマネ" ],
	[ "星井",   "hoshii",    "美希",   "miki",    14, 159, 44, "11月23日",  "B", 84, 55, 82, undef, "バードウォッチング、友達とおしゃべり" ],
	[ "我那覇", "ganaha",    "響",     "hibiki",  15, 152, 41, "10月10日",  "A", 86, 58, 83, undef, "編み物、卓球" ],
	[ "四条",   "shijou",    "貴音",   "takane",  17, 169, 49, "1月21日",   "B", 90, 62, 92, undef, "ひとりになること、月を見ること" ],

	[ "高木",   "takagi",    "順一郎", "junnichirou", 55, 180, 73, "7月6日", "AB", "秘密", "秘密", "秘密", undef, "カゲ踏み、クレナフレックス" ],
	[ "音無",   "otonashi",  "小鳥",   "kotori", "2x歳", 159, 49, "9月9日", "AB", "秘密", "秘密", "秘密", undef, "TVを見ること、妄想" ],
];
my $name_map = {};
my $name_match;

for (my $i = 0; $i < scalar(@$list); $i++) {
	my $idol = $list->[$i];
	$idol->[12] = "$idol->[9]-$idol->[10]-$idol->[11]";
	$idol->[ 4] = "$idol->[ 4]歳" if $idol->[ 4] =~ /^\d+$/;
	$idol->[ 5] = "$idol->[ 5]cm" if $idol->[ 5] =~ /^\d+$/;
	$idol->[ 6] = "$idol->[ 6]kg" if $idol->[ 6] =~ /^\d+$/;
	$idol->[ 9] = "$idol->[ 9]cm" if $idol->[ 9] =~ /^\d+$/;
	$idol->[10] = "$idol->[10]cm" if $idol->[10] =~ /^\d+$/;
	$idol->[11] = "$idol->[11]cm" if $idol->[11] =~ /^\d+$/;

	for (my $j = 0; $j < 4; $j++) {
		$name_map->{$idol->[$j]} = $idol;
	}
}

$name_map->{"社長"} = $name_map->{"高木"};
$name_match = join("|", keys(%$name_map));
$name_match = qr/$name_match/i;


sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	while ($message =~ /\bimasinfo:(\S+)\b/ig) {
		my $cmd = $1;

		if ($cmd =~ /^($name_match)(?:ちゃん|さん|くん|さま|君|様)?の($param_match)$/) {
			my $name = $1;
			my $paramname = $2;
			my $idol = $name_map->{$name};
			my $fname = $idol->[0];
			my $gname = $idol->[2];
			my $paramidx = $param_map->{$paramname};
			my $paramval = $idol->[$paramidx];
			$paramname = $param_names[$paramidx];
			$channel->notice("$fname$gname"."の"."$paramname = $paramval");
		} elsif ($cmd =~ /^($param_match)が(\S+)/) {
			my $paramname = $1;
			my $paramval = $2;
			my $paramidx = $param_map->{$paramname};
			$paramname = $param_names[$paramidx];
			foreach my $idol (@$list) {
				if ($idol->[$paramidx] eq $paramval) {
					my $fname = $idol->[0];
					my $gname = $idol->[2];
					$channel->notice("$fname$gname"."の"."$paramname = $paramval");
				}
			}
		}
	}
}

###############################################################################

return 1;
