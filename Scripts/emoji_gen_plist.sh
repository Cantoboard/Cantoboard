#!/bin/bash

scrapy runspider ./scrap_ios_emoji.py -O emoji_by_ios_version.json
./emoji_filter_and_explode.py
plutil -convert xml1 ios_emoji_ordered_12.1.json -o ../ISEmojiView/Source/Assets/ISEmojiList_iOS12.1.plist
plutil -convert xml1 ios_emoji_ordered_13.2.json -o ../ISEmojiView/Source/Assets/ISEmojiList_iOS13.2.plist
plutil -convert xml1 ios_emoji_ordered_14.2.json -o ../ISEmojiView/Source/Assets/ISEmojiList_iOS14.2.plist
plutil -convert xml1 ios_emoji_ordered_14.5.json -o ../ISEmojiView/Source/Assets/ISEmojiList_iOS14.5.plist
plutil -convert xml1 ios_emoji_ordered_15.4.json -o ../ISEmojiView/Source/Assets/ISEmojiList_iOS15.4.plist