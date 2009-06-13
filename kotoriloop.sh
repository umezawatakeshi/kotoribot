#!/bin/sh
# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

cd $(dirname $0)

while true; do
	STIME=$(date +%s)
	./kotoribot.pl "$@"
	ETIME=$(date +%s)
	if [ $(expr ${STIME} + 60) -gt ${ETIME} ]; then break; fi
done
