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

#import <MobileCoreServices/MobileCoreServices.h>


@interface ResourceLoader () <DownloadSessionDelegate>
{
    BOOL isLoadingComplete;
    NSUInteger totalLength;
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
    
    // Don't have any data at all for this request
    
    if (totalLength < startOffset)
    {
        NSLog(@"NO DATA FOR REQUEST");
        return NO;
    }
    
    NSUInteger unreadBytes = totalLength - (NSUInteger)startOffset;
    
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
   
    NSData *dataFromFile =  [FileManagementHelper fetchDataFromFileWithName:[self.delegate fileNameOfCurrentVideo]
                                                                   atOffset:startOffset
                                                                 withLength:numberOfBytesToRespondWith];
    
    [dataRequest respondWithData:dataFromFile];
    
    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = totalLength >= endOffset;
    return didRespondFully;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"didCancelLoadingRequest");
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


- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    if (contentInformationRequest == nil || self.downloadSession.response == nil)
    {
        return;
    }
    
    NSString *mimeType = [self.downloadSession.response MIMEType];
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = [self.downloadSession.response expectedContentLength];
    
}

- (void)addNewChunckOfData:(NSData *)data
{
    totalLength += data.length;
    NSLog(@" length %ld", data.length);
    [FileManagementHelper writeAtFileWithName:[self.delegate fileNameOfCurrentVideo] dataChunck:data];
}


@end