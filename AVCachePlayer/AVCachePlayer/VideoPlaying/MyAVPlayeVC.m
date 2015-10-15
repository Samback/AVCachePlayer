//
//  MyAVPlayeVC.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/14/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "MyAVPlayeVC.h"

@interface MyAVPlayeVC ()<AVAssetResourceLoaderDelegate, NSURLSessionDelegate>
{
    BOOL isLoadingComplete;
}
@property (nonatomic, strong) NSURL *baseVideoLink;

@property (nonatomic, strong) NSMutableData *videoData;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) AVURLAsset *vidAsset;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *avlayer;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableArray *pendingRequests;
@end

@implementation MyAVPlayeVC

- (void)setUpLink:(NSString *)link
{
    if (link) {
        
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:link] resolvingAgainstBaseURL:NO];
        components.scheme = @"streaming";
        self.baseVideoLink = [components URL];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupVideoPlayerConfiguration];

    // Do any additional setup after loading the view.
}

- (void)setupVideoPlayerConfiguration
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_baseVideoLink options:nil];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    self.pendingRequests = [NSMutableArray array];

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if(isLoadingComplete == YES)
    {
        //NSLog(@"LOADING WAS COMPLETE");
        [self.pendingRequests addObject:loadingRequest];
        [self processPendingRequests];
        return YES;
    }
    
    if (self.connection == nil)
    {
        NSURL *interceptedURL = [loadingRequest.request URL];
        NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:interceptedURL resolvingAgainstBaseURL:NO];
        actualURLComponents.scheme = @"http";
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[actualURLComponents URL]];
        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [self.connection setDelegateQueue:[NSOperationQueue mainQueue]];
        
        isLoadingComplete = NO;
        [self.connection start];
    }
    
    [self.pendingRequests addObject:loadingRequest];
    return YES;
}


/**
 NSURLConnection Delegate Methods
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"didReceiveResponse");
    self.videoData = [NSMutableData data];
    self.response = (NSHTTPURLResponse *)response;
    [self processPendingRequests];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"Received Data - appending to video & processing request");
    [self.videoData appendData:data];
    [self writeToLogFile:data];
    [self processPendingRequests];
}


-(void) writeToLogFile:(NSData *)data
{
    //get the documents directory:
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"hydraLog.mp4"];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
    if (fileHandle){
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }
    else{
        [data writeToFile:fileName atomically:YES];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"connectionDidFinishLoading::WriteToFile");
    
    [self processPendingRequests];
//    [self.videoData writeToFile:[self getVideoCachePath:self.vidSelected] atomically:YES];
}


/**
 AVURLAsset resource loader methods
 */

- (void)processPendingRequests
{
    NSMutableArray *requestsCompleted = [NSMutableArray array];
    
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
    if (contentInformationRequest == nil || self.response == nil)
    {
        return;
    }
    
    NSString *mimeType = [self.response MIMEType];
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = [self.response expectedContentLength];

}


- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    long long startOffset = dataRequest.requestedOffset;
    if (dataRequest.currentOffset != 0)
    {
        startOffset = dataRequest.currentOffset;
    }
    
    // Don't have any data at all for this request
    if (self.videoData.length < startOffset)
    {
        NSLog(@"NO DATA FOR REQUEST");
        return NO;
    }
    
    // This is the total data we have from startOffset to whatever has been downloaded so far
    NSUInteger unreadBytes = self.videoData.length - (NSUInteger)startOffset;
    
    // Respond with whatever is available if we can't satisfy the request fully yet
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    
    [dataRequest respondWithData:[self.videoData subdataWithRange:NSMakeRange((NSUInteger)startOffset, numberOfBytesToRespondWith)]];
    
    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = self.videoData.length >= endOffset;
    
    return didRespondFully;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"didCancelLoadingRequest");
    [self.pendingRequests removeObject:loadingRequest];
}


/**
 KVO
 */

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    if (context == StatusObservationContext)
//    {
//        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
//        
//        if (status == AVPlayerStatusReadyToPlay) {
//            [self initHud];
//            [self play:NO];
//        } else if (status == AVPlayerStatusFailed)
//        {
//            NSLog(@"ERROR::AVPlayerStatusFailed");
//            
//        } else if (status == AVPlayerItemStatusUnknown)
//        {
//            NSLog(@"ERROR::AVPlayerItemStatusUnknown");
//        }
//        
//    } else if (context == CurrentItemObservationContext) {
//        
//        
//    } else if (context == RateObservationContext) {
//        
//        
//    } else if (context == BufferObservationContext){
//        
//        
//    } else if (context == playbackLikelyToKeepUp) {
//        
//        if (self.player.currentItem.playbackLikelyToKeepUp)
//            
//            
//            }
//    
//} else if (context == playbackBufferEmpty) {
//    
//    if (self.player.currentItem.playbackBufferEmpty)
//    {
//        NSLog(@"Video Asset is playable: %d", self.videoAsset.isPlayable);
//        
//        NSLog(@"Player Item Status: %ld", self.player.currentItem.status);
//        
//        NSLog(@"Connection Request: %@", self.connection.currentRequest);
//        
//        NSLog(@"Video Data: %lu", (unsigned long)self.videoData.length);
//        
//        
//    }
//    
//} else if(context == playbackBufferFull) {
//    
//    
//} else {
//    
//    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//}
//
//}

@end
