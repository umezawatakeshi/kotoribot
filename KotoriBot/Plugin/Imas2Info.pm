# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

package KotoriBot::Plugin::Imas2Info;

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

my $nsuffix_match = qr/ちゃん|さん|くん|さま|ちん|君|様/;

# ひとまず誕生日と血液型は変わっていないものとしておく
my $idollist = [
	# 名字      f-name       名前,     g-name,    歳 身長  重  誕生日       血   乳  腰  尻     3S  趣味
	[ "天海",   "amami",     "春香",   "haruka",  17, 158, "不明", "4月3日",    "O", 83, 56, 82, undef, "不明", "中村繪里子" ],
	[ "如月",   "kisaragi",  "千早",   "chihaya", 16, 162, "不明", "2月25日",   "A", 72, 55, 78, undef, "不明", "今井麻美" ],
	[ "萩原",   "hagiwara",  "雪歩",   "yukiho",  17, 155, "不明", "12月24日",  "A", 81, 56, 81, undef, "不明", "浅倉杏美" ],
	[ "高槻",   "takatsuki", "やよい", "yayoi",   14, 145, "不明", "3月25日",   "O", 74, 54, 78, undef, "不明", "仁後真耶子" ],
	[ "秋月",   "akizuki",   "律子",   "ritsuko", 19, 156, "不明", "6月23日",   "A", 85, 57, 85, undef, "不明", "若林直美" ],
	[ "三浦",   "miura",     "あずさ", "azusa",   21, 168, "不明", "7月19日",   "O", 91, 59, 86, undef, "不明", "たかはし智秋" ],
	[ "水瀬",   "minase",    "伊織",   "iori",    15, 153, "不明", "5月5日",   "AB", 77, 54, 79, undef, "不明", "釘宮理恵" ],
	[ "菊地",   "kikuchi",   "真",     "makoto",  17, 159, "不明", "8月29日",   "O", 75, 57, 78, undef, "不明", "平田宏美" ],
	[ "双海",   "futami",    "亜美",   "ami",     13, 158, "不明", "5月22日",   "B", 78, 55, 77, undef, "不明", "下田麻美" ],
	[ "双海",   "futami",    "真美",   "mami",    13, 158, "不明", "5月22日",   "B", 78, 55, 77, undef, "不明", "下田麻美" ],
	[ "星井",   "hoshii",    "美希",   "miki",    15, 161, "不明", "11月23日",  "B", 86, 55, 83, undef, "不明", "長谷川明子" ],
	[ "我那覇", "ganaha",    "響",     "hibiki",  16, 152, "不明", "10月10日",  "A", 83, 56, 80, undef, "不明", "沼倉愛美" ],
	[ "四条",   "shijou",    "貴音",   "takane",  18, 169, "不明", "1月21日",   "B", 90, 62, 92, undef, "不明", "原由実" ],
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

# 長さの降順にソートしておかないと、"双海亜美" が "双海" にマッチして真美の情報が出てきてしまう
$name_match = join("|", sort { length($b) <=> length($a) } keys(%$name_map));
$name_match = qr/$name_match/i;


sub on_public($$) {
	my($self, $who, $message) = @_;
	my $channel = $self->{channel};

	while ($message =~ /\bimas2info:(\S+)\b/ig) {
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
