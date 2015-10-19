//
//  VideoSetVC.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/14/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import "VideoSetVC.h"
#import "MyAVPlayeVC.h"
#import "ClipsDB.h"
#import "NSString+MD5.h"

@interface VideoSetVC () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *clips;
@property (nonatomic, strong) NSArray *downloadedClips;

@end

@implementation VideoSetVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateClipsInfo];
}

- (void)updateClipsInfo
{
    self.clips = [[ClipsDB sharedManager] clipList];
    self.downloadedClips = [[ClipsDB sharedManager] downloadedClips];
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[MyAVPlayeVC class]]) {
        MyAVPlayeVC *playerVC = (MyAVPlayeVC *)segue.destinationViewController;
        NSUInteger row =[self.tableView indexPathForCell:(UITableViewCell *)sender].row;
        [playerVC setUpLink:self.clips[row][1]];
    }
}


#pragma mark - UITableViewDelegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.clips.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ClipInfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = self.clips[indexPath.row][0];
    NSString *linkMD5 = [self.clips[indexPath.row][1] MD5];
    
    cell.detailTextLabel.text = [self.downloadedClips containsObject:linkMD5] ? @"Downloaded" : @"Open to download";
    return cell;
}

@end

