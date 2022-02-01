#ifndef NGRAM_H_
#define NGRAM_H_

#pragma pack(push,1)

enum NGramSectionId {
    trie = 0,
    weight = 1,
    isWord = 2,
};

struct NGramSectionHeader {
    size_t dataSizeInBytes;
    size_t dataOffset;
};

struct NGramHeader {
    const char magicHeader[8] = {'C', 'A', 'N', 'T', 'N', 'G', 'A', 'M'};
    short headerSizeInBytes = sizeof(NGramHeader);
    short version = 0;
    char maxN;
    size_t numOfEntries;
    NGramSectionHeader sections[3];
};

#pragma pack(pop)

typedef __fp16 Weight;

#endif  // NGRAM_H_
