//
//  ViewController.m
//  IOSStudy
//
//  Created by 振兴 刘 on 2018/9/12.
//  Copyright © 2018年 振兴 刘. All rights reserved.
//

#import "ViewController.h"
#import "DownloadPart.h"

#define NUM_THREAD_MAX 5
#define SIZE_RANGE 1024
#define URL_IMAGE @"http://d.ifengimg.com/mw978_mh598/p1.ifengimg.com/2018_37/66bd7579-e6f2-4f8d-9643-298110d82d1b_1DBE1D95711656DE8C4BB3234F8E20981515D179_w1080_h462.jpg"

@interface ViewController ()

@property(nonatomic, strong) NSString* mFilePath;
@property(nonatomic, assign) NSInteger mTotalSize;
@property(nonatomic, assign) NSInteger mPartSize;
@property(nonatomic, strong) NSMutableArray* mArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString* fileName = [URL_IMAGE lastPathComponent];
    _mFilePath = [self getFilePath:fileName];
    NSLog(@"文件路径:%@",_mFilePath);
    
    [self createFile];
    
    [self start];
}


- (NSURL*)getURL {
    NSString* s = URL_IMAGE;
    s = [s stringByAddingPercentEscapesUsingEncoding:s];
    return [NSURL URLWithString:s];
}

- (void)start {
    
    //创建信号量
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self requestTotalSize:semaphore];
    //[self resizeFile];
    
    //等待(阻塞线程)
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    [self calculatePartSize];
    
    [self download];
}

- (void)requestTotalSize:(dispatch_semaphore_t)semaphore {
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[self getURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [request setHTTPMethod:@"HEAD"];
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        __block typeof(self)weakself = self;
        NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (!error) {
                weakself.mTotalSize = response.expectedContentLength;
            }
            
            //发送
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
    });
}

- (void)calculatePartSize {
    _mPartSize = _mTotalSize / NUM_THREAD_MAX;
    if (_mTotalSize % NUM_THREAD_MAX != 0) {
        _mPartSize += 1;
    }
    
    if (_mPartSize % 2 != 0)
        _mPartSize += 1;
}

- (void)download {
    
     __block typeof(self)weakself = self;
    for (int i = 0; i < NUM_THREAD_MAX; i++) {
    
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            DownloadPart* part = [[DownloadPart alloc] init];
            part.mFilePath = weakself.mFilePath;
            part.mURL = [self getURL];
            part.mPartStart = i*weakself.mPartSize;
            part.mPartEnd = i*weakself.mPartSize + weakself.mPartSize - 1;
            part.mIndex = i;
            [part start];
            [weakself.mArray addObject:part];
        });
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
    else {
        [[NSFileManager defaultManager] removeItemAtPath:_mFilePath error:nil];
        [[NSFileManager defaultManager] createFileAtPath:_mFilePath contents:nil attributes:nil];
    }
}

- (void)resizeFile {
    NSFileHandle* handle = [NSFileHandle fileHandleForWritingAtPath:_mFilePath];
    [handle truncateFileAtOffset:_mTotalSize];
}

@end
