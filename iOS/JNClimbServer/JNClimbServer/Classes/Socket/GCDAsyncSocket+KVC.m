//
//  GCDAsyncSocket+KVC.m
//  JNClimbServer
//
//  Created by Jonathan on 2020/4/19.
//

#import "GCDAsyncSocket+KVC.h"
#import <objc/runtime.h>

static NSString *jn_socket_connect_store_key = @"jn_socket_connect_store_key";

@implementation GCDAsyncSocket (KVC)

- (void)retainConnect:(JNSocketConnect *)connect
{
    objc_setAssociatedObject(self, &jn_socket_connect_store_key, connect, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JNSocketConnect *)getConnect
{
    return objc_getAssociatedObject(self, &jn_socket_connect_store_key);
}

- (void)removeConnect
{
    objc_setAssociatedObject(self, &jn_socket_connect_store_key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
