//
//  ResourceLoader.h
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/17/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

extern NSString *AVCACHE_PLAYER_GET_DATA_NOTIFICATION;
extern NSString *AVCACHE_PLAYER_REMOVE_HUD_NOTIFICATION;
extern const NSString *AVCACHE_PLAYER_GET_DATA_OFFSET;
extern const NSString *AVCACHE_PLAYER_DATA_TOTAL_LENGTH;

@protocol ResourceLoaderDelegate <NSObject>
- (NSString *)fileNameOfCurrentVideo;
- (NSURL *)inputVideoURL;
@end

@interface ResourceLoader : NSObject <AVAssetResourceLoaderDelegate>
+ (instancetype)createResourceLoaderWithDelegate:(id<ResourceLoaderDelegate>)aDelegate;

- (void)cancellAllRequests;
- (BOOL)isFileDownloaded;
@end
