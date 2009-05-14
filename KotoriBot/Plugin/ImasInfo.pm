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
	"胸"           => 9,
	"乳"           => 9,
	"ウエスト"     => 10,
	"ウェスト"     => 10,
	"腹囲"         => 10,
	"腰"           => 10,
	"ヒップ"       => 11,
	"尻"           => 11,
	"スリーサイズ" => 12,
	"趣味"         => 13,
	"声優"         => 14,
	"中の人"       => 14,
};
my @param_names = (
	"名字", "family name", "名前", "given name",
	"年齢", "身長", "体重", "誕生日", "血液型",
	"バスト", "ウエスト", "ヒップ", "スリーサイズ",
	"趣味", "声優",
);

my @infolist = (
	4, 5, 6, 7, 8,
	9, 10, 11,
	13, 14,
);

my $param_match;

$param_match = join("|", keys(%$param_map));
$param_match = qr/$param_match/i;

my $nsuffix_match = qr/ちゃん|さん|くん|さま|君|様/;

my $idollist = [
	# 名字      f-name       名前,     g-name,    歳 身長  重  誕生日       血   乳  腰  尻     3S  趣味
	[ "天海",   "amami",     "春香",   "haruka",  16, 158, 45, "4月3日",    "O", 83, 56, 80, undef, "おかし作り、カラオケ", "中村繪里子" ],
	[ "如月",   "kisaragi",  "千早",   "chihaya", 15, 162, 41, "2月25日",   "A", 72, 55, 78, undef, "音楽鑑賞（クラシック）", "今井麻美" ],
	[ "萩原",   "hagiwara",  "雪歩",   "yukiho",  16, 154, 40, "12月24日",  "A", 80, 55, 81, undef, "MY詩集を書くこと、日本茶", "落合祐里香" ],
	[ "高槻",   "takatsuki", "やよい", "yayoi",   13, 145, 37, "3月25日",   "O", 72, 54, 77, undef, "オセロ", "仁後真耶子" ],
	[ "秋月",   "akizuki",   "律子",   "ritsuko", 18, 156, 43, "6月23日",   "A", 85, 57, 85, undef, "資格取得、分析すること", "若林直美" ],
	[ "三浦",   "miura",     "あずさ", "azusa",   20, 168, 48, "7月19日",   "O", 91, 59, 86, undef, "犬の散歩", "たかはし智秋" ],
	[ "水瀬",   "minase",    "伊織",   "iori",    14, 150, 39, "5月5日",   "AB", 77, 54, 79, undef, "海外旅行、ショッピング", "釘宮理恵" ],
	[ "菊地",   "kikuchi",   "真",     "makoto",  16, 157, 42, "8月29日",   "O", 73, 56, 76, undef, "スポーツ全般", "平田宏美" ],
	[ "双海",   "futami",    "亜美",   "ami",     12, 149, 39, "5月22日",   "B", 74, 53, 77, undef, "メール、モノマネ", "下田麻美" ],
	[ "双海",   "futami",    "真美",   "mami",    12, 149, 39, "5月22日",   "B", 74, 53, 77, undef, "メール、モノマネ", "下田麻美" ],
	[ "星井",   "hoshii",    "美希",   "miki",    14, 159, 44, "11月23日",  "B", 84, 55, 82, undef, "バードウォッチング、友達とおしゃべり", "長谷川明子" ],
	[ "我那覇", "ganaha",    "響",     "hibiki",  15, 152, 41, "10月10日",  "A", 86, 58, 83, undef, "編み物、卓球", "沼倉愛美" ],
	[ "四条",   "shijou",    "貴音",   "takane",  17, 169, 49, "1月21日",   "B", 90, 62, 92, undef, "ひとりになること、月を見ること", "原由実" ],

	[ "高木",   "takagi",    "順一朗", "junnichirou", 55, 180, 73, "7月6日", "AB", "秘密", "秘密", "秘密", undef, "カゲ踏み、クレナフレックス", "徳丸完" ],
	[ "音無",   "otonashi",  "小鳥",   "kotori", "2x歳", 159, 49, "9月9日", "AB", "秘密", "秘密", "秘密", undef, "TVを見ること、妄想", "滝田樹里" ],
];
my $name_map = {};
my $name_match;

for (my $i = 0; $i < scalar(@$idollist); $i++) {
	my $idol = $idollist->[$i];
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
	$name_map->{"$idol->[0]$idol->[2]"} = $idol;
}

$name_map->{"社長"} = $name_map->{"高木"};
$name_map->{"高木社長"} = $name_map->{"高木"};
$name_match = join("|", keys(%$name_map));
$name_match = qr/$name_match/i;


sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	while ($message =~ /\bimasinfo:(\S+)\b/ig) {
		my $cmd = $1;

		if (("と".$cmd."と") =~ /^((?:と$name_match(?:$nsuffix_match)?)+)の((?:(?:$param_match)と)+)$/) {
			my $names = $1;
			my $paramnames = $2;
			while ($names =~ /と($name_match)(?:$nsuffix_match)?/g) {
				my $name = lc($1);
				my $idol = $name_map->{$name};
				my $fname = $idol->[0];
				my $gname = $idol->[2];
				while ($paramnames =~ /($param_match)と/g) {
					my $paramname = $1;
					my $paramidx = $param_map->{$paramname};
					my $paramval = $idol->[$paramidx];
					$paramname = $param_names[$paramidx];
					$channel->notice("$fname$gname"."の"."$paramname = $paramval");
				}
			}
		} elsif ($cmd =~ /^($name_match)(?:$nsuffix_match)?(?:の(?:すべて|ぜんぶ|全て|全部))?$/) {
			my $name = lc($1);
			my $idol = $name_map->{$name};
			my $fname = $idol->[0];
			my $gname = $idol->[2];
			foreach my $paramidx (@infolist) {
				my $paramval = $idol->[$paramidx];
				my $paramname = $param_names[$paramidx];
				$channel->notice("$fname$gname"."の"."$paramname = $paramval");
			}
		} elsif ($cmd =~ /^(?:みんな|全員)の($param_match)$/) {
			my $paramname = $1;
			my $paramidx = $param_map->{$paramname};
			$paramname = $param_names[$paramidx];
			foreach my $idol (@$idollist) {
				my $fname = $idol->[0];
				my $gname = $idol->[2];
				my $paramval = $idol->[$paramidx];
				$channel->notice("$fname$gname"."の"."$paramname = $paramval");
			}
		} elsif ($cmd =~ /^($param_match)が(\S+)/) {
			my $num = 0;
			my $paramname = $1;
			my $paramval = $2;
			my $paramidx = $param_map->{$paramname};
			$paramname = $param_names[$paramidx];
			foreach my $idol (@$idollist) {
				if ($idol->[$paramidx] eq $paramval) {
					my $fname = $idol->[0];
					my $gname = $idol->[2];
					$channel->notice("$fname$gname"."の"."$paramname = $paramval");
					$num++;
				}
			}
			$channel->notice("ひとりもいません") if $num == 0;
		}
	}
}

###############################################################################

return 1;
