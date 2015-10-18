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




@interface MyAVPlayeVC () <ResourceLoaderDelegate>
@property (nonatomic, strong) NSURL *baseVideoLink;
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
    }
}

- (ResourceLoader *)resourceLoader
{
    if (!_resourceLoader) {
        _resourceLoader = [ResourceLoader createResourceLoaderWithDelegate:self];
    }
    return _resourceLoader;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupVideoPlayerConfiguration];

    // Do any additional setup after loading the view.
}

- (void)setupVideoPlayerConfiguration
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_baseVideoLink options:nil];
    [asset.resourceLoader setDelegate:self.resourceLoader
                                queue:dispatch_get_main_queue()];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
}

#pragma mark - ResourceLoaderDelegate methods
- (NSString *)fileNameOfCurrentVideo
{
    return ((NSURL *)[_baseVideoLink copy]).description ;
}

@end
