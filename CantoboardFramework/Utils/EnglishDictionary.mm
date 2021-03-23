//
//  leveldb.cpp
//  CantoboardFramework
//
//  Created by Alex Man on 3/22/21.
//

#include <fstream>
#include <string>

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
    leveldb::Status status = leveldb::DB::Open(options, [dbPath UTF8String], &db);
    
    if (!status.ok()) {
        NSLog(@"Failed to open DB %@. Error: %s", dbPath, status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to open DB." userInfo:nil];
    }
    
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

+ (bool)createDb:(NSString*) textFilePath dbPath:(NSString*) dbPath {
    NSLog(@"createDbFromTextFile %@ -> %@", textFilePath, dbPath);
    
    leveldb::DB* db;
    leveldb::Options options;
    options.create_if_missing = true;
    
    ifstream dictFile([textFilePath UTF8String]);
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dbPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    leveldb::Status status = leveldb::DB::Open(options, [dbPath UTF8String], &db);
    if (!status.ok()) {
        NSLog(@"Failed to open DB %@. Error: %s", dbPath, status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to open DB." userInfo:nil];
    }
    
    string line;
    leveldb::WriteBatch batch;
    while (getline(dictFile, line)) {
        if (*line.rbegin() == '\r') line.pop_back();
        /*if (line.find("Sino") != string::npos) {
            NSLog(@"UUFFOO '%s'", line.c_str());
        }*/
        batch.Put(line, leveldb::Slice());
    }
    
    leveldb::Status writeStatus = db->Write(leveldb::WriteOptions(), &batch);
    if (!writeStatus.ok()) {
        NSLog(@"Failed to insert into DB. Error: %s", status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to insert into DB." userInfo:nil];
    }
    
    db->CompactRange(nullptr, nullptr);
    dictFile.close();
    delete db;
    
    return self;
}

@end
