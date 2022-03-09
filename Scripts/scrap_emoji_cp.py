#!/usr/bin/env python3
# coding=utf-8

# scrapy runspider scrap_emoji_cp.py -O emoji_codepoints.json

import scrapy

class EmojiSpider(scrapy.Spider):
    name = "emoji_codepoints"
    start_urls = [
        'https://emojipedia.org/emoji/',
    ]

    def parse(self, response):
        emoji_name_tuples = response.css('table.emoji-list > tr > td > a')

        for emoji_name_tuple in emoji_name_tuples:
            try:
                emoji_char = emoji_name_tuple.css('span::text').get()
                emoji_name = emoji_name_tuple.css('a::text').get().strip()

                # print(emoji_char, emoji_name)

                output = {
                    'emoji_char': emoji_char,
                    'emoji_name': emoji_name,
                }

                # print(emoji)
                yield output
                # break
            except:
                print(emoji_name_tuple.getall())
                raise
