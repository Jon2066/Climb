//
//  JNClimbWebSocket.h
//  AFNetworking
//
//  Created by Jonathan on 2020/4/18.
//

#import <Foundation/Foundation.h>
#import "JNTunnelModel.h"
#import <NetworkExtension/NetworkExtension.h>

NS_ASSUME_NONNULL_BEGIN

@interface JNLocalServer : NSObject

@property (nonatomic, strong) JNTunnelModel *model;

- (instancetype)initWithTunnelModel:(JNTunnelModel *)model;

- (void)start;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
