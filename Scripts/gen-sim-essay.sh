#!/bin/bash

cat ../CantoboardFramework/Data/Rime/essay.txt | grep -E "^.\t" > /tmp/essay-1char-t.txt
opencc -i /tmp/essay-1char-t.txt -o /tmp/essay-1char-s.txt -c hk2s.json
comm -13 /tmp/essay-1char-t.txt /tmp/essay-1char-s.txt > /tmp/essay-1char-s-uniq.txt
cat /tmp/essay-1char-s-uniq.txt | awk -F "\t" '{ printf("%s\t%.0f\n", $1,$2*0.9) }' > /tmp/essay-1char-s-uniq-with-freq.txt
cat /tmp/essay-1char-s-uniq-with-freq.txt | awk -F $'\t' '{count[$1]+=$2} END {for (word in count) printf("%s\t%d\n", word, count[word])}' > /tmp/essay-1char-s-uniq-with-freq-dedup.txt
cat ../CantoboardFramework/Data/Rime/essay.txt /tmp/essay-1char-s-uniq-with-freq-dedup.txt > ../CantoboardFramework/Data/Rime/essay-s1c.txt