//
//  VideoSetVC.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/14/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import "VideoSetVC.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface VideoSetVC ()

@end

@implementation VideoSetVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[AVPlayerViewController class]]) {
        AVPlayerViewController *playerVC = (AVPlayerViewController *)segue.destinationViewController;
        NSURL *url = [NSURL URLWithString:@"http://sample-videos.com/video/mp4/720/big_buck_bunny_720p_50mb.mp4"];
        playerVC.player = [[AVPlayer alloc] initWithURL:url];
        
    }
}
@end
