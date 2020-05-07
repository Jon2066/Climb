//
//  GCDAsyncSocket+KVC.h
//  JNClimbServer
//
//  Created by Jonathan on 2020/4/19.
//

#import "GCDAsyncSocket.h"
#import "JNSocketConnect.h"
NS_ASSUME_NONNULL_BEGIN

@interface GCDAsyncSocket (KVC)

- (void)retainConnect:(JNSocketConnect *)connect;

- (JNSocketConnect *)getConnect;

- (void)removeConnect;

@end

NS_ASSUME_NONNULL_END
