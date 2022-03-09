#!/usr/bin/env python3
# coding=utf-8

import json
import itertools
import unicodedata

groups = dict()

with open('emoji_by_ios_version.json', 'r') as f:
  emoji_by_ios_version_list = json.load(f)
  emoji_by_ios_version = dict()
  for tuple in emoji_by_ios_version_list:
    ios_version = tuple['ios_version']
    if ios_version not in emoji_by_ios_version:
      emoji_by_ios_version[ios_version] = set()

    emoji = tuple['emoji']
    emoji_by_ios_version[ios_version].add(emoji)

    if 'group' in tuple:
      group_prototype = tuple['group']
      if group_prototype not in groups:
        groups[group_prototype] = []
      if emoji not in groups[group_prototype]:
        groups[group_prototype].append(emoji)

  unique_ios_versions = emoji_by_ios_version.keys()

for k in groups:
  groups[k].append(k)
  groups[k].sort()

unique_ios_versions = list(unique_ios_versions)
unique_ios_versions.sort()
for ios_version in unique_ios_versions:
  print("Generating iOS json for", ios_version)
  avail_emojis = emoji_by_ios_version[ios_version]

  with open('ios_emoji_ordered.json', 'r') as f:
    ios_emoji_ordered = json.load(f)

  for cat in ios_emoji_ordered:
    new_emojis = []
    for emoji in cat['emojis']:
      is_available = emoji in avail_emojis
      if len(emoji) > 1 and not is_available:
        if emoji[-1] == '\ufe0f':
          emoji = emoji[:-1]
          is_available = emoji in avail_emojis
      elif emoji[-1] != '\ufe0f' and not is_available:
        emoji = emoji + '\ufe0f'
        is_available = emoji in avail_emojis
      if not is_available:
        print("Removed", emoji, list(map(lambda c: hex(ord(c)), emoji)))
        continue
      if emoji in groups:
        new_emojis.append(groups[emoji])
      else:
        new_emojis.append(emoji)
    cat['emojis'] = new_emojis

  json_string = json.dumps(ios_emoji_ordered)
  with open('ios_emoji_ordered_{}.json'.format(ios_version), 'w') as outfile:
    outfile.write(json_string)
