//
//  leveldb.cpp
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

+ (bool)createEnglishDictionary:(NSArray*) textFilePaths dictDbPath:(NSString*) dictDbPath {
    DDLogInfo(@"createEnglishDictionary %@ -> %@", textFilePaths, dictDbPath);
    
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
        
        [[NSFileManager defaultManager] createDirectoryAtPath:dictDbPath withIntermediateDirectories:YES attributes:nil error:nil];
        
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
    
    return self;
}

@end
