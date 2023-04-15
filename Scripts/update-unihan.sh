#!/bin/bash

source ~/workspace/personal/unihan-etl/venv/bin/activate
# Dump selected fields in Unihan to csv 
unihan-etl -s https://www.unicode.org/Public/15.1.0/ucd/Unihan.zip -F csv -f kRSUnicode kTotalStrokes kIICore kUnihanCore2020 --destination ../CantoboardTestApp/UnihanSource/Unihan12.csv 

# DOS2UNIX
gsed -i 's/\r//g' ../CantoboardTestApp/UnihanSource/Unihan12.csv

# Dump all chars in Hong Kong Core sets
echo "char,IsHCoreSim" > /tmp/UnihanH.csv
csvgrep ../CantoboardTestApp/UnihanSource/Unihan12.csv -c kIICore -m H | csvcut -c char | sed 's/$/,h/g' >> /tmp/UnihanH.csv

# Simplify chars in Hong Kong Core sets
opencc -i /tmp/UnihanH.csv -o /tmp/UnihanHSim.csv -c hk2s.json

csvjoin -c char --left ../CantoboardTestApp/UnihanSource/Unihan12.csv /tmp/UnihanHSim.csv > /tmp/a.csv
cp /tmp/a.csv ../CantoboardTestApp/UnihanSource/Unihan12.csv

# Remove chars not supported by iOS/macOS
/Users/alexman/Library/Developer/Xcode/DerivedData/Cantoboard-bhikvctrhuqyamayyipqvwokfjom/Build/Products/Debug/MissingGlyphRemover --line ../CantoboardTestApp/UnihanSource/Unihan12.csv
