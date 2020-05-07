//
//  SCDataHexString.h
//  Pods
//
//  Created by Jonathan on 2019/7/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JNDataHexString : NSObject

+ (NSData *)convertHexStrToData:(NSString *)str;
+ (NSString *)convertDataToHexStr:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
