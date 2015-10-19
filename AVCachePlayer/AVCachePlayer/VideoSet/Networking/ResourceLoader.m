//
//  ResourceLoader.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/17/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import "ResourceLoader.h"
#import "FileManagementHelper.h"
#import "DownloadSession.h"
#import "ClipsDb.h"

#import <MobileCoreServices/MobileCoreServices.h>

NSString *AVCACHE_PLAYER_GET_DATA_NOTIFICATION = @"AVCACHE_PLAYER_GET_DATA_NOTIFICATION";
NSString *AVCACHE_PLAYER_REMOVE_HUD_NOTIFICATION = @"AVCACHE_PLAYER_REMOVE_HUD_NOTIFICATION";
NSString const *AVCACHE_PLAYER_GET_DATA_OFFSET = @"AVCACHE_PLAYER_GET_DATA_OFFSET";
NSString const *AVCACHE_PLAYER_DATA_TOTAL_LENGTH = @"AVCACHE_PLAYER_DATA_TOTAL_LENGTH";

@interface ResourceLoader () <DownloadSessionDelegate>
{
    BOOL  isLoadingComplete;
    NSUInteger sumLength;
    NSUInteger videoBytesLength;
}
@property (nonatomic, strong) NSMutableArray *pendingRequests;
@property (nonatomic, strong) DownloadSession *downloadSession;
@property (nonatomic, weak) id <ResourceLoaderDelegate>delegate;
@end

@implementation ResourceLoader

- (NSMutableArray *)pendingRequests
{
    if (!_pendingRequests) {
        _pendingRequests = @[].mutableCopy;
    }
    return _pendingRequests;
}

+ (instancetype)createResourceLoaderWithDelegate:(id<ResourceLoaderDelegate>)aDelegate
{
    ResourceLoader *resourceLoader = [[ResourceLoader alloc] init];
    if (resourceLoader) {
        resourceLoader.delegate = aDelegate;
    }
    return resourceLoader;
}


- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if(isLoadingComplete == YES)
    {
        [self.pendingRequests addObject:loadingRequest];
        [self processPendingRequests];
        return YES;
    }
    
    if (self.downloadSession == nil)
    {
        self.downloadSession = [DownloadSession createDownloadSessionWithURL:[loadingRequest.request URL]
                                                                   urlScheme:[self.delegate inputVideoURL].scheme
                                                                withDelegate:self];
       
        [self.downloadSession resume];
        isLoadingComplete = NO;
    }
    
    [self.pendingRequests addObject:loadingRequest];
    return YES;
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    long long startOffset = dataRequest.requestedOffset;
    if (dataRequest.currentOffset != 0)
    {
        startOffset = dataRequest.currentOffset;
    }
    
    if (sumLength < startOffset)
    {
        NSLog(@"This data was not loaded yet");
        return NO;
    }
    
    NSUInteger unreadBytes = sumLength - (NSUInteger)startOffset;
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    NSData *dataFromFile =  [FileManagementHelper fetchDataFromFileWithName:[self.delegate fileNameOfCurrentVideo]
                                                                   atOffset:startOffset
                                                                 withLength:numberOfBytesToRespondWith];
    
    [dataRequest respondWithData:dataFromFile];
    if (!dataFromFile) {
        return NO;
    }
    
    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = sumLength >= endOffset;
    return didRespondFully;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.pendingRequests removeObject:loadingRequest];
}

- (void)processPendingRequests
{
    NSMutableArray *requestsCompleted = @[].mutableCopy;
    
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests)
    {
        [self fillInContentInformation:loadingRequest.contentInformationRequest];
        
        BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest];
        
        if (didRespondCompletely)
        {
            [requestsCompleted addObject:loadingRequest];
            [loadingRequest finishLoading];
        }
    }
    
    [self.pendingRequests removeObjectsInArray:requestsCompleted];
}

- (void)cancellAllRequests
{
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests){
        [loadingRequest finishLoading];
    }
    [self.pendingRequests removeAllObjects];
    [self.downloadSession.dataTask cancel];
    [self.downloadSession.session  finishTasksAndInvalidate];
    [[NSNotificationCenter defaultCenter] postNotificationName:AVCACHE_PLAYER_REMOVE_HUD_NOTIFICATION
                                                        object:nil];
}


- (BOOL)isFileDownloaded
{
    return isLoadingComplete;
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    if (contentInformationRequest == nil || self.downloadSession.response == nil){
        return;
    }
   
    videoBytesLength = contentInformationRequest.contentLength;
    NSString *mimeType = [self.downloadSession.response MIMEType];
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = [self.downloadSession.response expectedContentLength];
}

- (void)addNewChunckOfData:(NSData *)data
{
    sumLength += data.length;
    [[NSNotificationCenter defaultCenter] postNotificationName:AVCACHE_PLAYER_GET_DATA_NOTIFICATION
                                                        object:nil
                                                      userInfo:@{AVCACHE_PLAYER_GET_DATA_OFFSET : @(sumLength),
                                                                 AVCACHE_PLAYER_DATA_TOTAL_LENGTH : @(videoBytesLength) }];
    
    [FileManagementHelper writeAtFileWithName:[self.delegate fileNameOfCurrentVideo] dataChunck:data];
    if (videoBytesLength == sumLength && videoBytesLength != 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AVCACHE_PLAYER_REMOVE_HUD_NOTIFICATION
                                                            object:nil];
        [[ClipsDB sharedManager] markFileWithLink:[self.delegate inputVideoURL].absoluteString];
        isLoadingComplete = YES;
    }
}


@end
