//
//  leveldb.cpp
//  CantoboardFramework
//
//  Created by Alex Man on 3/22/21.
//

#include <fstream>
#include <string>
#include <algorithm>

#import <Foundation/Foundation.h>

#include <leveldb/db.h>
#include <leveldb/cache.h>
#include <leveldb/write_batch.h>

#include "Utils.h"

using namespace std;

@implementation EnglishDictionary {
    leveldb::DB* db;
}

- (id)init:(NSString*) dbPath {
    self = [super init];
    
    leveldb::Options options;
    options.block_cache = leveldb::NewLRUCache(1024); // Reduce cache size to 1kb.
    options.reuse_logs = true;
    leveldb::Status status = leveldb::DB::Open(options, [dbPath UTF8String], &db);
    
    if (!status.ok()) {
        NSLog(@"Failed to open DB %@. Error: %s", dbPath, status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to open DB." userInfo:nil];
    }
    
    [FileUnlocker unlockAllOpenedFiles];
    
    return self;
}

- (void)dealloc {
    delete db;
    db = nullptr;
}

- (bool)hasWord:(NSString*) word {
    leveldb::ReadOptions options;
    options.fill_cache = false;
    string val;
    leveldb::Status status;
    status = db->Get(options, [word UTF8String], &val);
    if (status.ok()) return true;
    status = db->Get(options, [[word lowercaseString] UTF8String], &val);
    if (status.ok()) return true;
    return false;
}

+ (bool)createDb:(NSArray*) textFilePaths dbPath:(NSString*) dbPath {
    NSLog(@"createDbFromTextFile %@ -> %@", textFilePaths, dbPath);
    
    leveldb::DB* db;
    leveldb::Options options;
    options.create_if_missing = true;
    
    leveldb::Status status = leveldb::DB::Open(options, [dbPath UTF8String], &db);
    if (!status.ok()) {
        NSLog(@"Failed to open DB %@. Error: %s", dbPath, status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to open DB." userInfo:nil];
    }
    
    leveldb::WriteBatch batch;
    string line;
    for (NSString* textFilePath in textFilePaths) {
        ifstream dictFile([textFilePath UTF8String]);
        
        [[NSFileManager defaultManager] createDirectoryAtPath:dbPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        while (getline(dictFile, line)) {
            if (*line.rbegin() == '\r') line.pop_back();
            transform(line.begin(), line.end(), line.begin(), [](unsigned char c){ return tolower(c); });
            /*if (line.find("Sino") != string::npos) {
                NSLog(@"UUFFOO '%s'", line.c_str());
            }*/
            if (line.empty()) continue;
            batch.Put(line, leveldb::Slice());
        }
        dictFile.close();
    }
    
    leveldb::Status writeStatus = db->Write(leveldb::WriteOptions(), &batch);
    if (!writeStatus.ok()) {
        NSLog(@"Failed to insert into DB. Error: %s", status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to insert into DB." userInfo:nil];
    }
    
    db->CompactRange(nullptr, nullptr);
    delete db;
    
    return self;
}

@end
