//
//  main.cpp
//  NGramBuilder
//
//  Created by Alex Man on 12/20/21.
//

#include <fstream>
#include <iostream>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <string.h>
#include <unicode/ustring.h>

#include "marisa.h"
#include "marisa/iostream.h"

#include "opencc.h"

#include "NGram.h"
#include "dynamic_bitset.hpp"

using namespace std;
using namespace marisa;
using namespace sul;

// #define DEBUG_BUILD_DICT
const char* rimeDictPaths[] = {
    "../CantoboardFramework/Data/Rime/essay.txt",
    "../CantoboardFramework/Data/Rime/jyut6ping3.dict.yaml",
    "../CantoboardFramework/Data/Rime/jyut6ping3.maps.dict.yaml",
    "../CantoboardFramework/Data/Rime/jyut6ping3.phrase.dict.yaml",
};

bool endsWith(std::string const &fullString, std::string const &ending) {
    if (fullString.length() >= ending.length()) {
        return (0 == fullString.compare (fullString.length() - ending.length(), ending.length(), ending));
    } else {
        return false;
    }
}

// Treat entries in rime dict as "words"/詞組.
unordered_set<string> readWordEntries() {
    unordered_set<string> words;
    
    for (auto rimeDictPath : rimeDictPaths) {
        ifstream dictFile(rimeDictPath);
        
        // Special case for essay.txt.
        bool startProcessing = endsWith(rimeDictPath, ".txt");
        std::string line;
        
        while (getline(dictFile, line)) {
            if (line == "...") {
                startProcessing = true;
                continue;
            }
            
            if (startProcessing && line.length() > 0 && *line.begin() != '#') {
                auto first_tab_index = line.find_first_of('\t');
                if (first_tab_index == string::npos) {
                    first_tab_index = line.length();
                }
                const string word(line.data(), first_tab_index);
                words.insert(word);
            }
        }
        dictFile.close();
    }
    
    return words;
}

unordered_map<string, float> readDict(opencc_t opencc) {
    unordered_map<string, float> ret;
    
    ios::sync_with_stdio(false);

    ifstream dictFile("ngram.csv");
    
    if (!dictFile.is_open()) throw std::runtime_error("Could not open file");
    
    bool isFirstLine = true;
    std::string line;
    int lineNum = 0;
    while (getline(dictFile, line)) {
        lineNum++;
        if (isFirstLine) {
            isFirstLine = false;
            continue;
        }
        
        if (line.empty()) continue;
        
        try {
            const char* text = strtok(line.data(), ",");
            // Skip conditional prob:
            strtok(NULL, ",");
            float prob = std::stof(strtok(NULL, ","));
            size_t textLen = strlen(text);
            if (textLen == 0) continue;
            
            char* converted = opencc_convert_utf8(opencc, text, textLen);
            if (ret.find(converted) == ret.end()) {
                ret[converted] = prob;
            } else {
                ret[converted] = max(ret[converted], prob);
            }
            opencc_convert_utf8_free(converted);
            converted = nullptr;
#ifdef DEBUG_BUILD_DICT
            // cout << text << " " << converted << " " << ret[converted] << "\n";
#endif
        } catch (exception& ex) {
            cerr << "Error parsing line: " << lineNum << " content: " << line << " exception: " << ex.what();
            throw;
        }
    }
    
    dictFile.close();
    
    return ret;
}

void writeNGram(size_t maxN, const Trie& trie, const Weight* weights, const dynamic_bitset<unsigned char>& isWordList, const string& outputFile) {
    ofstream ngramFileStream(outputFile);
        
    NGramHeader header;
    header.numOfEntries = trie.size();
    header.maxN = maxN;
    
    size_t currentPtr = header.headerSizeInBytes;
    header.sections[NGramSectionId::trie].dataOffset = currentPtr;
    header.sections[NGramSectionId::trie].dataSizeInBytes = trie.io_size();
    currentPtr += header.sections[NGramSectionId::trie].dataSizeInBytes;
    
    header.sections[weight].dataOffset = currentPtr;
    header.sections[weight].dataSizeInBytes = header.numOfEntries * sizeof(Weight);
    currentPtr += header.sections[weight].dataSizeInBytes;
    
    size_t isWordListByteLen = (isWordList.size() + 7) / 8;
    header.sections[isWord].dataOffset = currentPtr;
    header.sections[isWord].dataSizeInBytes = isWordListByteLen;
    currentPtr += header.sections[isWord].dataSizeInBytes;
    
    ngramFileStream.write((char*)&header, header.headerSizeInBytes);
    
    write(ngramFileStream, trie);
    ngramFileStream.write((char*)weights, trie.size() * sizeof(Weight));
    ngramFileStream.write((char*)isWordList.data(), isWordListByteLen);
    
    ngramFileStream.close();
}

size_t countCodePointsInUtf8String(const string& utf8String) {
    UChar textInUtf16[1024];
    UErrorCode pErrorCode = UErrorCode::U_ZERO_ERROR;
    u_strFromUTF8(textInUtf16, sizeof(textInUtf16) / sizeof(*textInUtf16), nullptr, utf8String.c_str(), -1, &pErrorCode);
    return u_countChar32(textInUtf16, -1);
}

int buildNGram(const char* openccConfigPath, const string& ngramOutputFile) {
    Trie trie;
    
    cout << "Converting using openccConfigPath=" << openccConfigPath << " to " << ngramOutputFile << endl;
    
    opencc_t opencc = opencc_open(openccConfigPath);
    unordered_map<string, float> dict = readDict(opencc);
    Keyset keyset;
    
    unordered_set<string> added;
    size_t maxN = 0;
    for (auto it = dict.begin(); it != dict.end(); ++it) {
        const string& text = it->first;
        auto w = it->second;
        
        maxN = max(maxN, countCodePointsInUtf8String(text));
#ifdef DEBUG_BUILD_DICT
        // cout << text << "=" << it->second << endl;
#endif
        if (added.find(text) != added.end()) {
            cerr << "Ignoring duplicated key: " << text << endl;
            continue;
        }
        keyset.push_back(text, w);
        added.insert(text);
    }
    trie.build(keyset, MARISA_TEXT_TAIL | MARISA_WEIGHT_ORDER);
    
    Weight* weights = new Weight[trie.size()];
    
    unordered_set<string> words = readWordEntries();
    dynamic_bitset<unsigned char> isWordList(keyset.size());
    
    for (size_t keyIndex = 0; keyIndex < keyset.size(); ++keyIndex) {
        const auto& key = keyset[keyIndex];
        const auto id = key.id();
        const auto keyStr = string(key.str());
        const auto w = dict[keyStr];
#ifdef DEBUG_BUILD_DICT
        cout << id << "," << keyStr << "=" << w << "\n";
#endif
        weights[id] = w;
        isWordList[id] = words.find(keyStr) != words.end();
    }
    
    std::cout << "File size: " << trie.io_size() + trie.size() * sizeof(Weight) << "\n";
    
#ifdef DEBUG_BUILD_DICT
    Agent agent;
    agent.set_query("死");
    while (trie.predictive_search(agent)) {
        cout << agent.key().id() << "," << agent.key().str() << "," << weights[agent.key().id()] << "\n";
    }
#endif
    
    writeNGram(maxN, trie, weights, isWordList, ngramOutputFile);
    
    delete[] weights;
    
    opencc_close(opencc);
    
    return 0;
}

int main(int argc, const char * argv[]) {
    buildNGram("../CantoboardFramework/Data/Rime/opencc/t2hk.json", "../CantoboardFramework/Data/InstallToCache/NGram/zh_HK.ngram");
    buildNGram("../CantoboardFramework/Data/Rime/opencc/t2s.json", "../CantoboardFramework/Data/InstallToCache/NGram/zh_CN.ngram");

    return 0;
}
