#!/bin/bash

cat ../CantoboardFramework/Data/Rime/jyut6ping3.words.dict.yaml | sed 's/jyut6ping3/quick5/g' | sed 's/\t.*$//g' > ../CantoboardFramework/Data/Rime/quick5.words_t.dict.yaml
opencc -i ../CantoboardFramework/Data/Rime/quick5.words_t.dict.yaml -o ../CantoboardFramework/Data/Rime/quick5.words_s.dict.yaml -c hk2s.json
