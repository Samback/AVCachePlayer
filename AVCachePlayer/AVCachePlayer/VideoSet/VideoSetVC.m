//
//  VideoSetVC.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/14/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import "VideoSetVC.h"
#import "MyAVPlayeVC.h"

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
    if ([segue.destinationViewController isKindOfClass:[MyAVPlayeVC class]]) {
        MyAVPlayeVC *playerVC = (MyAVPlayeVC *)segue.destinationViewController;
       [playerVC setUpLink:@"http://youtubeinmp4.com/redirect.php?video=iSR_GmaaMj4&r=7%2BLGbNFYs%2FC5q381fD5yDA5BTEZfgjy%2BeiLzLrYRRbo%3D"];
    }
}
//http://youtubeinmp4.com/redirect.php?video=MzqyGfQcilA&r=fewjCqH0bQLuZroQE8as%2FCGsDEW9WFOT6kKc%2FXP91Sc%3D

@end
