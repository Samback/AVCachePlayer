//
//  MyAVPlayeVC.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/14/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>


#import "MyAVPlayeVC.h"
#import "MyAVPlayeVC+HUDWorker.h"
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

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupVideoPlayerConfiguration];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.player cancelPendingPrerolls];
    if (self.resourceLoader && ![self.resourceLoader isFileDownloaded]) {
        NSError *error = [FileManagementHelper tryToDeleteFileWithName:[self.baseVideoLink absoluteString]];
        if (error) {
            NSLog(@"Error it was an error duaring removing of file %@", error.localizedDescription);
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:AVCACHE_PLAYER_REMOVE_HUD_NOTIFICATION
                                                        object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if (self.resourceLoader) {
        [self.resourceLoader cancellAllRequests];
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
        [self startDownloadHUD];
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
