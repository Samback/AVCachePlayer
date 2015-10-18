//
//  DownloadSession.h
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/17/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DownloadSessionDelegate <NSObject>
- (void)addNewChunckOfData:(NSData *)data;
- (void)processPendingRequests;
@end

@interface DownloadSession : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong, readonly) NSURLSession *session;
@property (nonatomic, strong, readonly) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;

+ (instancetype)createDownloadSessionWithURL:(NSURL *)url urlScheme:(NSString *)scheme withDelegate:(id<DownloadSessionDelegate>)aDelegate ;

- (void)resume;
@end
