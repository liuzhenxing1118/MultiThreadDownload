//
//  DownloadPart.h
//  IOSStudy
//
//  Created by 振兴 刘 on 2018/9/12.
//  Copyright © 2018年 振兴 刘. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadPart : NSObject

@property(nonatomic, strong) NSString* mFilePath;
@property(nonatomic, strong) NSURL*    mURL;
@property(nonatomic, assign) NSInteger mPartStart;
@property(nonatomic, assign) NSInteger mPartEnd;
@property(nonatomic, assign) NSInteger mRequestStart;
@property(nonatomic, assign) NSInteger mRequestEnd;
@property(nonatomic, assign) NSInteger mIndex;

- (void)start;

@end

