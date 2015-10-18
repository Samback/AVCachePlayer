//
//  FileManagementHelper.m
//  AVCachePlayer
//
//  Created by Max Tymchiy on 10/17/15.
//  Copyright © 2015 Max Tymchiy. All rights reserved.
//

#import "FileManagementHelper.h"
#import "NSString+MD5.h"

@implementation FileManagementHelper


+ (NSString *)fullPathToFileName:(NSString *)fileName
{
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *name = [[fileName MD5] stringByAppendingString:@".mp4"];
    return [documentsDirectory stringByAppendingPathComponent:name];
}

+ (void)writeAtFileWithName:(NSString *)fileName dataChunck:(NSData *)data
{
    
    NSString *fullPathToFileName =  [FileManagementHelper fullPathToFileName:fileName];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:fullPathToFileName];
    
    if (fileHandle){
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }
    else{
        [data writeToFile:fullPathToFileName atomically:YES];
    }
}


+ (NSData *)fetchDataFromFileWithName:(NSString *)fileName atOffset:(NSUInteger)startOffset withLength:(NSUInteger)bytesLengthToRead
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[FileManagementHelper fullPathToFileName:fileName]];
    NSUInteger endOfFileOffset = [fileHandle seekToEndOfFile];
    if (endOfFileOffset < bytesLengthToRead) {
        return [NSData data];
    }
    if (fileHandle){
        [fileHandle seekToFileOffset:startOffset];
        NSData *data = [fileHandle readDataOfLength:bytesLengthToRead];
        [fileHandle closeFile];
        return data;
    }
    else{
        NSLog(@"IN here");
        [fileHandle seekToFileOffset:startOffset];
        return [fileHandle readDataOfLength:bytesLengthToRead];
    }
}




@end
