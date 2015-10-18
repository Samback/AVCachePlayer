//
//  ResourceLoader.h
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/17/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol ResourceLoaderDelegate <NSObject>
- (NSString *)fileNameOfCurrentVideo;
- (NSURL *)inputVideoURL;
- (void)finishDownload:(BOOL)downloadFlag withError:(NSError *)error;
@end

@interface ResourceLoader : NSObject <AVAssetResourceLoaderDelegate>
+ (instancetype)createResourceLoaderWithDelegate:(id<ResourceLoaderDelegate>)aDelegate;
- (void)cancellAllRequests;

- (BOOL)isFileDownloaded;
@end
