//
//  ClipsDB.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/19/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import "ClipsDB.h"
#import "NSString+MD5.h"


static NSString *kClipKey = @"kClipKey";
@interface ClipsDB ()
@property (nonatomic, readwrite) NSArray *clipList;
@end

@implementation ClipsDB
+ (instancetype)sharedManager {
    static ClipsDB *sharedClipsDB = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClipsDB = [[self alloc] init];
    });
    return sharedClipsDB;
}

- (NSArray *)clipList
{
    if (!_clipList) {
        _clipList = @[
                      @[@"Cat", @"http://youtubeinmp4.com/redirect.php?video=iSR_GmaaMj4&r=7%2BLGbNFYs%2FC5q381fD5yDA5BTEZfgjy%2BeiLzLrYRRbo%3D"],
                      @[@"Droider", @"http://youtubeinmp4.com/redirect.php?video=MzqyGfQcilA&r=fewjCqH0bQLuZroQE8as%2FCGsDEW9WFOT6kKc%2FXP91Sc%3D"],
                      @[@"Selfi" , @"http://youtubeinmp4.com/redirect.php?video=IeBgVwSbE1A&r=3LvlsDNh3wntcPFjGmWjAU2dmq6Qi%2BkQrx%2FAcVGNeGg%3D"]
                      ];
    }
    return _clipList;
}

- (void)markFileWithLink:(NSString *)filePath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedClips = [defaults objectForKey:kClipKey];
    NSMutableArray *updatedClip = nil;
    if (savedClips) {
        updatedClip = [NSMutableArray arrayWithArray:savedClips];
    } else {
        updatedClip = @[].mutableCopy;
    }
    
    [updatedClip addObject:[filePath MD5]];
    [defaults setObject:updatedClip forKey:kClipKey];
    [defaults synchronize];
}

- (NSArray *)downloadedClips
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:kClipKey];
}

- (BOOL)isFileWithLinkAlreadyDownloaded:(NSString *)filePath
{
    NSString *md5FilePath = [filePath MD5];
    return [[[ClipsDB sharedManager] downloadedClips] containsObject:md5FilePath];
}


@end
