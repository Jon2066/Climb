//
//  JNEncryption.h
//  JNTool
//
//  Created by Jonathan on 2020/4/19.
//

#import <Foundation/Foundation.h>
#import "JNTunnelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface JNEncryption : NSObject

+ (instancetype)shareInstance;

- (NSString *)serverRSAPubKey;

- (NSString *)clientRSAPrivateKey;

- (NSData *)encryptData:(NSData *)data tunnelModel:(JNTunnelModel *)tunnelModel;

- (nullable NSData *)decryptData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END
