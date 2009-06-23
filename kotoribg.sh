#!/bin/sh
# 文字コードはＵＴＦ－８、改行コードはＬＦのみ
# $Id$

cd $(dirname $0)

nohup ./kotoriloop.sh "$@" >/dev/null &
sleep 1
