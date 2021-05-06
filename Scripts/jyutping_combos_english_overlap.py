# !/usr/bin/python
# coding=utf-8

from itertools import product

initials = ['', 'b', 'p', 'm', 'f', 'd', 't', 'n', 'l', 'g', 'k', 'ng', 'h', 'gw', 'kw', 'w', 'z', 'c', 's', 'j']
finals = ['aa', 'aai', 'aau', 'aam', 'aan', 'aang', 'aap', 'aat', 'aak', 'a', 'ai', 'au', 'am', 'an', 'ang', 'ap', 'at', 'ak', 'e', 'ei', 'eu', 'em', 'eng', 'ep', 'ek', 'i', 'iu', 'im', 'in', 'ing', 'ip', 'it', 'ik', 'o', 'oi', 'ou', 'on', 'ong', 'ot', 'ok', 'u', 'ui', 'un', 'ung', 'ut', 'uk', 'eoi', 'eon', 'eot', 'oe', 'oeng', 'oet', 'oek', 'yu', 'yun', 'yut', 'm', 'ng']
tones = ['1', '2', '3', '4', '5', '6']

# tuples = list(product(initials, finals, tones))
tuples = list(product(initials, finals))

combos = set()
overlapWords = set()

for tuple in tuples:
    combo = tuple[0] + tuple[1]
    combos.add(combo)

with open('/tmp/dict.txt') as f:
    lines = f.read().splitlines()

for line in lines:
    word = line.strip().lower()
    if word in combos:
        overlapWords.add(word)

for overlapWord in sorted(overlapWords):
    print overlapWord
