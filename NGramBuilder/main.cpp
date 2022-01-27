//
//  main.cpp
//  NGramBuilder
//
//  Created by Alex Man on 12/20/21.
//

#include <fstream>
#include <iostream>
#include <unordered_map>
#include <unordered_set>
#include <string.h>
#include <unicode/ustring.h>

#include "marisa.h"
#include "marisa/iostream.h"

#include "opencc.h"

#include "ngram.h"

using namespace std;
using namespace marisa;

// #define DEBUG_BUILD_DICT

unordered_map<string, float> readDict(opencc_t opencc) {
    unordered_map<string, float> ret;
    
    ios::sync_with_stdio(false);

    ifstream dictFile("ngram.csv");
    
    if (!dictFile.is_open()) throw std::runtime_error("Could not open file");
    
    bool isFirstLine = true;
    std::string line;
    int lineNum = 0;
    while (!dictFile.eof()) {
        getline(dictFile, line);
        lineNum++;
        if (isFirstLine) {
            isFirstLine = false;
            continue;
        }
        
        if (line.empty()) continue;
        
        try {
            const char* text = strtok(line.data(), ",");
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
#ifdef DEBUG_BUILD_DICT
            // cout << text << " " << converted << " " << ret[converted] << "\n";
#endif
        } catch (exception& ex) {
            cerr << "Error parsing line: " << lineNum << " content: " << line << " exception: " << ex.what();
            throw;
        }
    }
    
    return ret;
}

void writeNGram(size_t maxN, const Trie& trie, const Weight* weights, const string& outputFile) {
    ofstream ngramFileStream(outputFile);
    
    NGramHeader header;
    header.numOfEntries = trie.size();
    header.maxN = maxN;
    header.sections[weight].dataOffset = header.headerSizeInBytes;
    header.sections[weight].dataSizeInBytes = header.numOfEntries * sizeof(Weight);
    header.sections[NGramSectionId::trie].dataOffset = header.headerSizeInBytes + header.sections[weight].dataSizeInBytes;
    header.sections[NGramSectionId::trie].dataSizeInBytes = trie.io_size();
    ngramFileStream.write((char*)&header, sizeof(header));
    
    ngramFileStream.write((char*)weights, trie.size() * sizeof(Weight));
    write(ngramFileStream, trie);
    
    ngramFileStream.close();
}

size_t countCodePointsInUtf8String(const string& utf8String) {
    UChar textInUtf16[1024];
    UErrorCode pErrorCode;
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
    
    for (size_t keyIndex = 0; keyIndex < keyset.size(); ++keyIndex) {
        const auto& key = keyset[keyIndex];
        const auto id = key.id();
        const auto keyStr = string(key.str());
        const auto w = dict[keyStr];
#ifdef DEBUG_BUILD_DICT
        cout << id << "," << keyStr << "=" << w << "\n";
#endif
        weights[id] = w;
    }
    
    std::cout << "File size: " << trie.io_size() + trie.size() * sizeof(Weight) << "\n";
    
#ifdef DEBUG_BUILD_DICT
    Agent agent;
    agent.set_query("死");
    while (trie.predictive_search(agent)) {
        cout << agent.key().id() << "," << agent.key().str() << "," << weights[agent.key().id()] << "\n";
    }
#endif
    
    writeNGram(maxN, trie, weights, ngramOutputFile);
    
    delete[] weights;
    
    opencc_close(opencc);
    
    return 0;
}

int main(int argc, const char * argv[]) {
    buildNGram("../CantoboardFramework/Data/Rime/opencc/t2hk.json", "../CantoboardFramework/Data/InstallToCache/NGram/zh_HK.ngram");
    buildNGram("../CantoboardFramework/Data/Rime/opencc/t2s.json", "../CantoboardFramework/Data/InstallToCache/NGram/zh_CN.ngram");

    return 0;
}
