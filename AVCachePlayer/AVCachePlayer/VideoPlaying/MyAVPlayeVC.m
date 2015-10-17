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




@interface MyAVPlayeVC ()<AVAssetResourceLoaderDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate>
{
    BOOL isLoadingComplete;
    NSUInteger totalLength;
    NSString *nameFile;
}
@property (nonatomic, strong) NSURL *baseVideoLink;
@property (nonatomic, strong) NSURLSession *session;
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
    nameFile = [NSDate date].description;

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
    
    if (self.session == nil)
    {
        NSURL *interceptedURL = [loadingRequest.request URL];
        NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:interceptedURL resolvingAgainstBaseURL:NO];
        actualURLComponents.scheme = @"http";
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[actualURLComponents URL]];
        
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                     delegate:self delegateQueue:[NSOperationQueue mainQueue]];

        NSURLSessionDataTask *downloadTask = [self.session dataTaskWithRequest:request];
        isLoadingComplete = NO;
        [downloadTask resume];
    }
    
    [self.pendingRequests addObject:loadingRequest];
    return YES;
}


- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    NSLog(@"Error %@", error);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    totalLength += data.length;
    [self writeToLogFile:data];
    [self processPendingRequests];
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
    self.response = (NSHTTPURLResponse *)response;
    [self processPendingRequests];
}

-(void) writeToLogFile:(NSData *)data
{
    //get the documents directory:
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *name = [nameFile stringByAppendingString:@".mp4"];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:name];
    
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
   
    if (totalLength < startOffset)
    {
        NSLog(@"NO DATA FOR REQUEST");
        return NO;
    }
    
    // This is the total data we have from startOffset to whatever has been downloaded so fa
    
    // This is the total data we have from startOffset to whatever has been downloaded so far
    NSUInteger unreadBytes = totalLength - (NSUInteger)startOffset;
    
    // Respond with whatever is available if we can't satisfy the request fully yet
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    
//    NSData *dataa = [self.videoData subdataWithRange:NSMakeRange((NSUInteger)startOffset, numberOfBytesToRespondWith)];
    
    NSData *dataFromFile = [self dataAtOffset:(NSUInteger)startOffset withLength:numberOfBytesToRespondWith];
    
//    if ([dataa isEqualToData:dataFromFile]) {
//        NSLog(@"Cool");
//    } else {
//        NSLog(@"Something wrong");
//    }
    
    [dataRequest respondWithData:dataFromFile];

    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = totalLength >= endOffset;
    return didRespondFully;
}


- (NSData *)dataAtOffset:(NSUInteger)offset withLength:(NSUInteger)bytes
{
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *name = [nameFile stringByAppendingString:@".mp4"];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:name];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:fileName];
    NSLog(@"Read bytes %ld", bytes);
    NSUInteger end = [fileHandle seekToEndOfFile];
    
    if (end < bytes) {
        NSLog(@"Not enough offset");
        return [NSData data];
    }
    if (fileHandle){
        [fileHandle seekToFileOffset:offset];
        NSData *data = [fileHandle readDataOfLength:bytes];
        [fileHandle closeFile];
        return data;
    }
    else{
        [fileHandle seekToFileOffset:offset];
        return [fileHandle readDataOfLength:bytes];
    }
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"didCancelLoadingRequest");
    [self.pendingRequests removeObject:loadingRequest];
}


@end
