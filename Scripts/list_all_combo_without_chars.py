# !/usr/bin/python
# coding=utf-8

from itertools import product

initials = ['', 'b', 'p', 'm', 'f', 'd', 't', 'n', 'l', 'g', 'k', 'ng', 'h', 'gw', 'kw', 'w', 'z', 'c', 's', 'j']
finals = ['aa', 'aai', 'aau', 'aam', 'aan', 'aang', 'aap', 'aat', 'aak', 'a', 'ai', 'au', 'am', 'an', 'ang', 'ap', 'at', 'ak', 'e', 'ei', 'eu', 'em', 'eng', 'ep', 'ek', 'i', 'iu', 'im', 'in', 'ing', 'ip', 'it', 'ik', 'o', 'oi', 'ou', 'on', 'ong', 'ot', 'ok', 'u', 'ui', 'un', 'ung', 'ut', 'uk', 'eoi', 'eon', 'eot', 'oe', 'oeng', 'oet', 'oek', 'yu', 'yun', 'yut', 'm', 'ng']
tones = ['1', '2', '3', '4', '5', '6']

tuples = list(product(initials, finals, tones))

combos = set()

for tuple in tuples:
    combo = tuple[0] + tuple[1] + tuple[2]
    combos.add(combo)

with open('/tmp/combo_with_words.txt') as f:
    lines = f.read().splitlines()

for line in lines:
    combos.discard(line.strip())

for combo in sorted(combos):
    print u"__此音無字__\t".encode('utf-8') + "gyu6 ngap3 ngoet1 beot1 " + combo
