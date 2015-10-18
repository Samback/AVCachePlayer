//
//  MyAVPlayeVC+HUDWorker.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/19/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import "ResourceLoader.h"

#import "MyAVPlayeVC+HUDWorker.h"
#import <MBProgressHUD/MBProgressHUD.h>

#import <objc/runtime.h>

@interface MyAVPlayeVC (HUDWorkerPrivate)
@property (nonatomic, strong) MBProgressHUD *hud;
@end

@implementation MyAVPlayeVC (HUDWorkerPrivate)

- (MBProgressHUD *)hud
{
    return  objc_getAssociatedObject(self, @selector(hud));
}

- (void)setHud:(MBProgressHUD *)aHUD
{
    objc_setAssociatedObject(self, @selector(hud), aHUD, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation MyAVPlayeVC (HUDWorker)


- (void)startDownloadHUD
{
    [self configurateHUD_UI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadHUD:) name:AVCACHE_PLAYER_GET_DATA_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopDownloadHUD) name:AVCACHE_PLAYER_REMOVE_HUD_NOTIFICATION object:nil];
    
}

- (void)configurateHUD_UI
{
    if (self.hud) {
        [self.hud hide:YES];
        self.hud = nil;
    }
    CGRect hudHolderRect =  CGRectMake(-35, 20, 150, 100);
    CGRect hudRect       =  CGRectMake(0, 0, 50, 50);
    UIView *hudHolder = [[UIView alloc] initWithFrame:hudHolderRect];
    hudHolder.backgroundColor = [UIColor clearColor];
    hudHolder.alpha = 0.4;
    [self.contentOverlayView addSubview:hudHolder];
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithFrame:hudRect];
    hud.removeFromSuperViewOnHide = YES;
    [self.view addSubview:hud];
    self.hud = hud;
    self.hud.mode = MBProgressHUDModeDeterminate;
    self.hud.color = [UIColor clearColor];
    [self.hud show:YES];
    [hudHolder addSubview:self.hud];
}

- (void)stopDownloadHUD
{
    MyAVPlayeVC *__weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.hud hide:YES];
        weakSelf.hud = nil;
    });
}

- (void)reloadHUD:(NSNotification *)notification
{
    if (notification.userInfo) {
        NSUInteger currentOffset = ((NSNumber *)notification.userInfo[AVCACHE_PLAYER_GET_DATA_OFFSET]).integerValue;
        NSUInteger totalLength = ((NSNumber *)notification.userInfo[AVCACHE_PLAYER_DATA_TOTAL_LENGTH]).integerValue;
        
        if (currentOffset > totalLength) {
            totalLength = currentOffset;
            currentOffset = 0;
        }
        
        MyAVPlayeVC *__weak weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            float progress = (float)((currentOffset * 1.0) / totalLength);
            [weakSelf.hud setProgress:progress];
        });
    }
    
}
@end
