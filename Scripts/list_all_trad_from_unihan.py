#!/usr/bin/env python3
import sys

# Assume csv in format:
# char,ucn,kIICore,kUnihanCore2020,kSimplifiedVariant,kRSUnicode
# If kIICore has H or T, or has kSimplifiedVariant, it's a trad char.
isHeader = True
for line in sys.stdin:
    if isHeader:
        isHeader = False
        continue
    line = line.strip()
    row = line.split(',')
    kIICore = row[2] + row[3]
    kSimplifiedVariant = row[4]
    kRSUnicode = row[5]
    if '\'' not in kRSUnicode: # and ('H' in kIICore or 'T' in kIICore or 'J' in kIICore):
        print(line[0])
