//
//  LevelDbTable.m
//  CantoboardFramework
//
//  Created by Alex Man on 3/22/21.
//

#include <fstream>
#include <string>
#include <algorithm>
#include <unordered_map>

#import <Foundation/Foundation.h>

#import <CocoaLumberjack/DDLogMacros.h>
static const DDLogLevel ddLogLevel = DDLogLevelDebug;

#include <leveldb/db.h>
#include <leveldb/cache.h>
#include <leveldb/write_batch.h>

#include "Utils.h"

using namespace std;

@implementation LevelDbTable {
    leveldb::DB* db;
}

- (id)init:(NSString*) dbPath createDbIfMissing:(bool) createDbIfMissing {
    self = [super init];
    
    leveldb::Options options;
    options.block_cache = leveldb::NewLRUCache(64);
    options.reuse_logs = true;
    options.create_if_missing = createDbIfMissing;
    leveldb::Status status = leveldb::DB::Open(options, [dbPath UTF8String], &db);
    
    if (!status.ok()) {
        DDLogInfo(@"Failed to open DB %@. Error: %s", dbPath, status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to open DB." userInfo:nil];
    }
    
    DDLogInfo(@"Opened English dictionary at %@.", dbPath);
    
    return self;
}

- (void)dealloc {
    delete db;
    db = nullptr;
}

- (NSString*)get:(NSString*) key {
    leveldb::ReadOptions options;
    options.fill_cache = false;
    string val;
    leveldb::Status status;
    status = db->Get(options, [key UTF8String], &val);
    if (status.ok()) {
        return [NSString stringWithUTF8String:val.c_str()];
    }
    return nil;
}

- (UnihanEntry)getUnihanEntry:(uint32_t) charInUtf32 {
    leveldb::ReadOptions options;
    options.fill_cache = false;
    string val;
    leveldb::Status status;
    status = db->Get(options, leveldb::Slice((char*)&charInUtf32, sizeof(charInUtf32)), &val);
    UnihanEntry result;
    memset(&result, 0, sizeof(result));
    if (status.ok()) {
        assert(val.length() == sizeof(UnihanEntry));
        memcpy(&result, val.c_str(), sizeof(UnihanEntry));
    }
    return result;
}

- (bool)put:(NSString*) key value:(NSString*) value {
    leveldb::Status status;
    status = db->Put(leveldb::WriteOptions(), [key UTF8String], [value UTF8String]);
    if (status.ok()) {
        return true;
    } else {
        DDLogInfo(@"Failed to put to db. Error: %s", status.ToString().c_str());
        return false;
    }
}

- (bool)delete:(NSString*) key {
    leveldb::Status status;
    status = db->Delete(leveldb::WriteOptions(), [key UTF8String]);
    if (status.ok()) {
        return true;
    } else {
        DDLogInfo(@"Failed to delete from db. Error: %s", status.ToString().c_str());
        return false;
    }
}

+ (void)createEnglishDictionary:(NSArray*) textFilePaths dictDbPath:(NSString*) dictDbPath {
    DDLogInfo(@"createEnglishDictionary %@ -> %@", textFilePaths, dictDbPath);
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dictDbPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    leveldb::DB* db;
    leveldb::Options options;
    options.create_if_missing = true;
    
    leveldb::Status status = leveldb::DB::Open(options, [dictDbPath UTF8String], &db);
    if (!status.ok()) {
        DDLogInfo(@"Failed to open DB %@. Error: %s", dictDbPath, status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to open DB." userInfo:nil];
    }
    
    // lowercased key -> list of strings with original cases.
    unordered_map<string, string> wordCasesMap;
    string line;
    for (NSString* textFilePath in textFilePaths) {
        DDLogInfo(@"Loading %@...", textFilePath);
        ifstream dictFile([textFilePath UTF8String]);
        
        while (getline(dictFile, line)) {
            if (*line.rbegin() == '\r') line.pop_back();
            if (line.empty() || line.find(',') != std::string::npos) continue;
            string key(line);
            transform(key.begin(), key.end(), key.begin(), [](unsigned char c){ return tolower(c); });
            
            auto it = wordCasesMap.find(key);
            if (it == wordCasesMap.end()) {
                wordCasesMap.insert(make_pair(string(key), string(line)));
            } else {
                it->second.append(",");
                it->second.append(line);
            }
        }
        dictFile.close();
    }
    
    leveldb::WriteBatch batch;
    for (auto it = wordCasesMap.begin(); it != wordCasesMap.end(); it++) {
        // DDLogInfo(@"%s -> %s\n", it->first.c_str(), it->second.c_str());
        batch.Put(it->first, it->second);
    }
    leveldb::Status writeStatus = db->Write(leveldb::WriteOptions(), &batch);
    if (!writeStatus.ok()) {
        DDLogInfo(@"Failed to insert into DB. Error: %s", status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to insert into DB." userInfo:nil];
    }
    
    db->CompactRange(nullptr, nullptr);
    delete db;
}

+ (void)createUnihanDictionary:(NSString*) csvPath dictDbPath:(NSString*) dbPath {
    DDLogInfo(@"createUnihanDictionary %@ -> %@", csvPath, dbPath);
    
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    
    leveldb::DB* db;
    leveldb::Options options;
    options.create_if_missing = true;
    
    leveldb::Status status = leveldb::DB::Open(options, [dbPath UTF8String], &db);
    if (!status.ok()) {
        DDLogInfo(@"Failed to open DB %@. Error: %s", dbPath, status.ToString().c_str());
        @throw [NSException exceptionWithName:@"UnihanDictionaryException" reason:@"Failed to open DB." userInfo:nil];
    }
    
    string line;
    ifstream csvFile([csvPath UTF8String]);
    
    leveldb::WriteBatch batch;
    bool hasSkippedHeader = false;
    while (getline(csvFile, line)) {
        if (!hasSkippedHeader) {
            hasSkippedHeader = true;
            continue;
        }
        
        if (*line.rbegin() == '\r') line.pop_back();
        if (line.empty()) continue;
        
        NSString *nsLine = [NSString stringWithUTF8String:line.c_str()];
        NSArray *parsed = [nsLine componentsSeparatedByString:@","];
        NSString *charUtf8InString = [parsed objectAtIndex:0];
        NSString *rsUnicodeTuple = [parsed objectAtIndex:2];
        int totalStroke = [[parsed objectAtIndex:3] intValue];
        NSString *iiCore = [parsed objectAtIndex:4];
        NSString *unihanCore = [parsed objectAtIndex:5];
        // If the char is in the simplified H Core set (簡體版香港常用字)
        NSString *iicoreHSim = [parsed objectAtIndex:6];
        
        const char* charUtf32InString = [charUtf8InString cStringUsingEncoding: NSUTF32StringEncoding];
        uint32_t cInUtf32 = ((uint32_t*)charUtf32InString)[0];
        
        if ([rsUnicodeTuple hasSuffix:@"'"]) {
            rsUnicodeTuple = [rsUnicodeTuple substringToIndex:[rsUnicodeTuple length] - 1];
        }
        
        NSArray *rsUnicodeParsed = [rsUnicodeTuple componentsSeparatedByString:@"."];
        int radical = [[rsUnicodeParsed objectAtIndex:0] intValue];
        int radicalStroke = [[rsUnicodeParsed objectAtIndex:1] intValue];
        
        UnihanEntry unihanEntry;
        unihanEntry.radical = radical;
        unihanEntry.radicalStroke = radicalStroke;
        unihanEntry.totalStroke = totalStroke;
        unihanEntry.iiCore = 0;
        if ([iiCore containsString:@"H"] || [iiCore containsString:@"T"]) {
             unihanEntry.iiCore |= IICoreT;
        }
        if ([unihanCore containsString:@"G"] || [iicoreHSim containsString:@"h"]) {
             unihanEntry.iiCore |= IICoreG;
        }
        
        if (radical == 0 || totalStroke == 0) {
            DDLogInfo(@"Ignoring char with 0 stroke %@", nsLine);
            continue;
            // @throw [NSException exceptionWithName:@"UnihanDictionaryException" reason:@"Bad Char." userInfo:nil];
        }
        
        leveldb::Slice key((char*)&cInUtf32, sizeof(cInUtf32));
        leveldb::Slice value((char*)&unihanEntry, sizeof(unihanEntry));
        batch.Put(key, value);
    }
    
    leveldb::Status writeStatus = db->Write(leveldb::WriteOptions(), &batch);
    if (!writeStatus.ok()) {
        DDLogInfo(@"Failed to insert into DB. Error: %s", status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to insert into DB." userInfo:nil];
    }
    
    csvFile.close();
    db->CompactRange(nullptr, nullptr);
    delete db;
    
    exit(0);
}

@end
