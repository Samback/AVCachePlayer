//
//  MyAVPlayeVC.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/14/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>


#import "MyAVPlayeVC.h"
#import "ResourceLoader.h"
#import "FileManagementHelper.h"



@interface MyAVPlayeVC () <ResourceLoaderDelegate>
@property (nonatomic, strong) NSURL *baseVideoLink;
@property (nonatomic, strong) NSURL *initialLink;
@property (nonatomic, strong) ResourceLoader *resourceLoader;
@end

@implementation MyAVPlayeVC

#pragma mark - Lazy instantiation
- (void)setUpLink:(NSString *)link
{
    if (link) {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:link] resolvingAgainstBaseURL:NO];
        components.scheme = @"streaming";
        self.baseVideoLink = [components URL];
        self.initialLink = [NSURL URLWithString:link];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupVideoPlayerConfiguration];

    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.player cancelPendingPrerolls];
    if (self.resourceLoader && ![self.resourceLoader isFileDownloaded]) {
        NSError *error = [FileManagementHelper tryToDeleteFileWithName:[self.baseVideoLink absoluteString]];
        NSLog(@"Error %@", error);
    }
}

- (void)setupVideoPlayerConfiguration
{
    if ([FileManagementHelper isDownloadedFileWithName:[_baseVideoLink absoluteString]]) {
        NSURL *filePathURL = [NSURL fileURLWithPath:[FileManagementHelper fullPathToFileName:[_baseVideoLink absoluteString]]];
        AVAsset *asset = [AVURLAsset URLAssetWithURL:filePathURL options:nil];
        AVPlayerItem *anItem = [AVPlayerItem playerItemWithAsset:asset];

         self.player = [AVPlayer playerWithPlayerItem:anItem];
        [self.player play];
    } else {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_baseVideoLink options:nil];
        self.resourceLoader = [ResourceLoader createResourceLoaderWithDelegate:self];
        [asset.resourceLoader setDelegate:self.resourceLoader
                                    queue:dispatch_get_main_queue()];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        [self.player play];
    }
}

#pragma mark - ResourceLoaderDelegate methods
- (NSString *)fileNameOfCurrentVideo
{
    return ((NSURL *)[_baseVideoLink copy]).description ;
}

- (NSURL *)inputVideoURL
{
    return _initialLink;
}

@end
