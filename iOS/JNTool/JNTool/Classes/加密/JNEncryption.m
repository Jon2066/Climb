//
//  JNEncryption.m
//  JNTool
//
//  Created by Jonathan on 2020/4/19.
//

#import "JNEncryption.h"
#import "ELEncryptAES.h"
#import "RSAObjC.h"
#import "JNDataHexString.h"


@interface JNEncryption ()
@property (nonatomic, strong) NSDictionary *keyDic;
@end
@implementation JNEncryption

+ (instancetype)shareInstance
{
    static JNEncryption *jn_encrytion = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        jn_encrytion = [[JNEncryption alloc] init];
    });
    return jn_encrytion;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:@"rsa_config" ofType:@"json"];
    NSString *content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSData *jsonData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    self.keyDic = dic;
}

- (NSString *)serverRSAPubKey
{
    return self.keyDic[@"server_pub"];
}

- (NSString *)clientRSAPrivateKey
{
    return self.keyDic[@"client_private"];
}


- (NSData *)encryptData:(NSData *)data tunnelModel:(JNTunnelModel *)tunnelModel
{
    NSString *keyType = @"AES|ECB";
    NSString *key = [self randomStringWithLength:32];
    NSString *iv =  nil;
    CCOptions options = kCCOptionPKCS7Padding | kCCOptionECBMode;
    ELEncryptMode eMode = ELEncryptAES128;
    NSInteger random = arc4random() % 3;
    if (random == 0) {
        eMode = ELEncryptAES128;
        key = [self randomStringWithLength:16];
    }
    else if(random == 1){
        eMode = ELEncryptAES192;
        key = [self randomStringWithLength:24];
    }
    else if(random == 2){
        eMode = ELEncryptAES256;
        key = [self randomStringWithLength:32];
    }
    if (arc4random() % 2) {
        keyType = @"AES|CBC";
        //iv必须是16位
        iv = [self randomStringWithLength:16];
        options = kCCOptionPKCS7Padding;
    }
    
    NSString *kString = [NSString stringWithFormat:@"%@|%@%@",keyType,key,iv?[@"|" stringByAppendingString:iv]:@""];
    
//    NSString *kRSA = [RSA encryptString:kString publicKey:[self serverRSAPubKey]];
    NSString *kRSA = [RSAObjC encrypt:kString PublicKey:[self serverRSAPubKey]];
    
    NSString *dataHexString = [JNDataHexString convertDataToHexStr:data];
    
    NSDictionary *dataDic = @{
        @"username":tunnelModel.userName,
        @"password":tunnelModel.password,
        @"data":dataHexString
    };
    NSData *dData = [NSJSONSerialization dataWithJSONObject:dataDic options:NSJSONWritingPrettyPrinted error:nil];
    NSData *aesData = [ELEncryptAES el_dataByEncrypt:dData key:key mode:eMode options:options iv:iv];
    if (!aesData.length) {
        return nil;
    }
    NSString *aesHexString =  [JNDataHexString convertDataToHexStr:aesData];
    NSError *error = nil;
    NSData*jsonData = [NSJSONSerialization dataWithJSONObject:@{
        @"k":kRSA,
        @"v":aesHexString
    } options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return nil;
    }
    NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@" " withString:@""];
    jsonString = [jsonString stringByAppendingString:@"#"];
    return [jsonString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)decryptData:(NSData *)data
{
    NSError *error = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        return nil;
    }
//    NSString *key = [RSA decryptString:dic[@"k"] privateKey:[self clientRSAPrivateKey]];
    NSString *key = [RSAObjC decrypt:dic[@"k"] PrivateKey:[self clientRSAPrivateKey]];

    if ([key isEqualToString:@""]) {
        return nil;
    }
    NSArray *keyArray = [key componentsSeparatedByString:@"|"];
    if (!keyArray.count) {
        return nil;
    }
    NSString *keyType = keyArray[0];
    NSString *iv = nil;
    if (![keyType isEqualToString:@"AES"]) {
        return nil;
    }
    NSString *aesKey = keyArray[2];
    ELEncryptMode eMode = ELEncryptAES128;
    if (aesKey.length == 24) {
        eMode = ELEncryptAES192;
    }
    else if (aesKey.length == 32){
        eMode = ELEncryptAES256;
    }

    if (keyArray.count == 4) {
        iv = keyArray[3];
    }
    CCOptions options = iv?kCCOptionPKCS7Padding:(kCCOptionPKCS7Padding | kCCOptionECBMode);
    NSString *receive = dic[@"v"];
    NSData *dataFromHex = [JNDataHexString convertHexStrToData:receive];
    if (!dataFromHex) {
        return nil;
    }
    NSData *decryptyData = [ELEncryptAES el_dataByDecrypt:dataFromHex key:aesKey mode:eMode options:options iv:iv];
    if (decryptyData.length == 0) {
        return nil;
    }
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:decryptyData options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        return nil;
    }
    NSString *originStr = jsonDic[@"data"];
    NSData *originData = [JNDataHexString convertHexStrToData:originStr];
    return originData;
}


-(NSString *)randomStringWithLength:(NSInteger)len {
     NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (NSInteger i = 0; i < len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((uint32_t)[letters length])]];
    }
    return randomString;
}
@end
