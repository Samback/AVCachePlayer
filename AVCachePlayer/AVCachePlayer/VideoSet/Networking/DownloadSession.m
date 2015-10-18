//
//  DownloadSession.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/17/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import "DownloadSession.h"
#import "FileManagementHelper.h"

@interface DownloadSession ()
@property (nonatomic, strong, readwrite) NSURLSession *session;
@property (nonatomic, strong, readwrite) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong, readwrite) NSHTTPURLResponse *response;
@property (nonatomic, weak) id<DownloadSessionDelegate> delegate;
@end

@implementation DownloadSession

+ (instancetype)createDownloadSessionWithURL:(NSURL *)url
                                   urlScheme:(NSString *)scheme
                                withDelegate:(id<DownloadSessionDelegate>)aDelegate
{
    DownloadSession *downloadSession = [[DownloadSession alloc] init];
    if (!downloadSession) {
        return nil;
    }
    downloadSession.delegate = aDelegate;
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:url
                                                        resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = scheme;
    NSURLRequest *request = [NSURLRequest requestWithURL:[actualURLComponents URL]];
    
    downloadSession.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:downloadSession delegateQueue:[NSOperationQueue mainQueue]];
    
    downloadSession.dataTask = [downloadSession.session dataTaskWithRequest:request];
    return downloadSession;
}

- (void)resume
{
    [self.dataTask resume];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    NSLog(@"Error %@", error);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.delegate addNewChunckOfData:data];
    [self.delegate processPendingRequests];
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
    self.response = (NSHTTPURLResponse *)response;
    [self.delegate processPendingRequests];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"connectionDidFinishLoading::WriteToFile");
    [self.delegate processPendingRequests];
}



@end
