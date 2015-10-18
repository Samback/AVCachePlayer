//
//  FileManagementHelper.h
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/17/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileManagementHelper : NSObject
+ (BOOL)isDownloadedFileWithName:(NSString *)fileName;
+ (NSString *)fullPathToFileName:(NSString *)fileName;
+ (void)writeAtFileWithName:(NSString *)fileName dataChunck:(NSData *)data;
+ (NSData *)fetchDataFromFileWithName:(NSString *)fileName atOffset:(NSUInteger)startOffset withLength:(NSUInteger)bytesLengthToRead;
+ (NSError *)tryToDeleteFileWithName:(NSString *)fileName;
@end
