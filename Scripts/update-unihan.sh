#!/bin/bash

source ~/workspace/personal/unihan-etl/venv/bin/activate
unihan-etl -s https://www.unicode.org/Public/11.0.0/ucd/Unihan.zip -F csv -f kRSUnicode kTotalStrokes kIICore --destination ../CantoboardTestApp/UnihanSource/Unihan12.csv 
gsed -i 's/\r//g' ../CantoboardTestApp/UnihanSource/Unihan12.csv
/Users/alexman/Library/Developer/Xcode/DerivedData/Cantoboard-bhikvctrhuqyamayyipqvwokfjom/Build/Products/Debug/MissingGlyphRemover --line ../CantoboardTestApp/UnihanSource/Unihan12.csv
