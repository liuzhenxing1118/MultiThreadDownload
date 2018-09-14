//
//  DownloadPart.m
//  IOSStudy
//
//  Created by 振兴 刘 on 2018/9/12.
//  Copyright © 2018年 振兴 刘. All rights reserved.
//

#import "DownloadPart.h"

#define SIZE_RANGE 1024


@interface DownloadPart ()

@end

@implementation DownloadPart

- (void)start {
    
    _mRequestStart = _mPartStart;
    
    while (_mRequestStart < _mPartEnd) {
        
        _mRequestEnd =_mRequestStart + SIZE_RANGE-1;
        if (_mRequestEnd > _mPartEnd)
            _mRequestEnd = _mPartEnd - 1;
        
        //创建信号量
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [self download:semaphore startIndex:_mRequestStart endIndex:_mRequestEnd];
        
        //等待(阻塞线程)
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void)download:(dispatch_semaphore_t)semaphore startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex {
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.mURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [request setHTTPMethod:@"GET"];
    
    NSString* range = [NSString stringWithFormat:@"Bytes=%ld-%ld",(long)startIndex, (long)endIndex];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    __block typeof(self)weakself = self;
    NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error) {
            [self writeToFile:data];
            weakself.mRequestStart += data.length;
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
}

- (void)writeToFile:(NSData*)data {
    
    NSFileHandle* handle = [NSFileHandle fileHandleForWritingAtPath:_mFilePath];
    if (handle) {
        @synchronized(self) {
            [handle seekToFileOffset:_mRequestStart];
            [handle writeData:data];
            [handle closeFile];
        }
    }
}

- (NSString*)getFilePath:(NSString*)fileName {
    
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [NSString stringWithFormat:@"%@%@%@", path, @"/", fileName];
}

- (void)createFile {
    if (![[NSFileManager defaultManager] fileExistsAtPath:_mFilePath]) {
        [[NSFileManager defaultManager] createFileAtPath:_mFilePath contents:nil attributes:nil];
    }
}

@end
