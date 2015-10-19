//
//  ClipsDB.h
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/19/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClipsDB : NSObject
@property (nonatomic, readonly) NSArray *clipList;
+ (instancetype)sharedManager;

- (void)markFileWithLink:(NSString *)filePath;
- (NSArray *)downloadedClips;
- (BOOL)isFileWithLinkAlreadyDownloaded:(NSString *)filePath;
@end
