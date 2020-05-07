//
//  JNRACManager.m
//  Climb
//
//  Created by Jonathan on 2020/4/18.
//  Copyright © 2020 JN. All rights reserved.
//

#import "JNPACManager.h"

@interface JNPACManager ()
@property (nonatomic, strong) NSArray *list;
@end

@implementation JNPACManager

+ (NSString *)loadPACFromFile
{
    NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"gfwlist" ofType:@"pac"];
    NSString *content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    return content;
}

+ (NSArray<NSString *> *)loadListFromFile
{
    NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"gfwlist" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *arr = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    return arr;
}

+ (instancetype)shareInstance
{
    static JNPACManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[JNPACManager alloc] init];
        manager.list = [self loadListFromFile];
    });
    return manager;
}

- (BOOL)needRemoteServer:(NSString *)string host:(NSString *__autoreleasing *)host port:(NSString *__autoreleasing *)port httpMethod:(NSString *__autoreleasing *)method
{
    NSArray *requestArr = [string componentsSeparatedByString:@"\r\n"];
    if (requestArr.count > 2) {
        NSString *hostString = requestArr[1];
        for (NSString *domain in self.list) {
            if ([hostString containsString:domain]) {
                return YES;
            }
        }
        [self getHost:host port:port method:method fromString:string];
    }
    return NO;
}

- (void)getHost:(NSString **)host
           port:(NSString **)port
         method:(NSString **)method
     fromString:(NSString *)string
{

    NSArray *requestArr = [string componentsSeparatedByString:@"\r\n"];
    NSString *requestString = nil;
    NSString *hostString = nil;
    if (requestArr.count > 1) {
        requestString = requestArr[0];
        hostString = requestArr[1];
    }
    else{
        return;
    }
    *host = [hostString stringByReplacingOccurrencesOfString:@"Host: " withString:@""];
    NSArray *arr = [requestString componentsSeparatedByString:@" "];
    *port = @"80";
    if (arr.count > 2) {
        *method = arr[0];
        NSString *url = arr[1];
        url = [url stringByReplacingOccurrencesOfString:@"://" withString:@""];
        if ([url containsString:@":"]) {
            NSString *portAndParams = [url componentsSeparatedByString:@":"].lastObject;
            *port = [portAndParams componentsSeparatedByString:@"/"].firstObject;
        }
    }
}
@end
