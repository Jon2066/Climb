//
//  ELEncryptAES.m
//  ELKitSDK
//
//  Created by YinLinLin on 2019/7/29.
//

#import "ELEncryptAES.h"

@implementation ELEncryptAES


+ (nullable NSData *)el_dataByEncrypt:(NSData *)data key:(NSString *)key mode:(ELEncryptMode)mode options:(CCOptions)options iv:(nullable NSString *)iv {
    NSData *encodeData = [self encryptOperation:kCCEncrypt mode:mode value:data key:key options:options iv:iv];
    return encodeData;
}

+ (nullable NSData *)el_dataByDecrypt:(NSData *)data key:(NSString *)key mode:(ELEncryptMode)mode options:(CCOptions)options iv:(nullable NSString *)iv {
    return [self encryptOperation:kCCDecrypt mode:mode value:data key:key options:options iv:iv];
}

+ (NSData *)encryptOperation:(CCOperation)operation mode:(ELEncryptMode)mode value:(NSData *)data key:(NSString *)key options:(CCOptions)options iv:(NSString *)iv {
    NSUInteger keySize;
    CCAlgorithm algorithm;
    NSUInteger blockSize;
    switch (mode) {
        case ELEncryptAES128: {
            keySize = kCCKeySizeAES128;
            algorithm = kCCAlgorithmAES128;
            blockSize = kCCBlockSizeAES128;
            break;
        }
        case ELEncryptAES192: {
            keySize = kCCKeySizeAES192;
            algorithm = kCCAlgorithmAES128;
            blockSize = kCCBlockSizeAES128;
            break;
        }
        case ELEncryptAES256: {
            keySize = kCCKeySizeAES256;
            algorithm = kCCAlgorithmAES128;
            blockSize = kCCBlockSizeAES128;
            break;
        }
        case ELEncryptDES: {
            keySize = kCCKeySizeDES;
            algorithm = kCCAlgorithmDES;
            blockSize = kCCBlockSizeDES;
            break;
        }
        case ELEncrypt3DES: {
            keySize = kCCKeySize3DES;
            algorithm = kCCAlgorithm3DES;
            blockSize = kCCBlockSize3DES;
            break;
        }
        default: {
            return nil;
        }
    }
    NSInteger keyLength = MAX(keySize, key.length);
    char keyPtr[keyLength + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = data.length;
    size_t bufferSize = dataLength + blockSize;
    void * buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    char ivPtr[blockSize+1];
    memset(ivPtr, 0, sizeof(ivPtr));
    if (iv != nil) {
        [iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    }
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          algorithm,
                                          options,
                                          keyPtr,
                                          keySize,
                                          ivPtr,
                                          data.bytes,
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        NSData * result = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        if (result != nil) {
            return result;
        }
    } else {
        if (buffer) {
            free(buffer);
            buffer = NULL;
        }
    }
    return nil;
}


@end
