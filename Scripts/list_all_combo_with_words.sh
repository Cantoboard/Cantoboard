#!/bin/sh

cat ../RimeSchema/Cantonese/jyut6ping3.dict.yaml | cut -d"	" -f2 | grep -v " " | sort -u | tee /tmp/combo_with_words.txt
