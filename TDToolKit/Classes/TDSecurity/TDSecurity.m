//
//  TDSecurity.m
//  Pods
//
//  Created by tiandy on 2019/1/26.
//

#import "TDSecurity.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <LocalAuthentication/LocalAuthentication.h>

static NSInteger const TDMD5ConfusionIndex = 10; ////与服务器端预定的插入位置
static NSString * const TDMD5Salt = @"PFdZ48fPszfEG0E2"; //与服务器端约定的盐(随机数)
static NSString * const TDMD5Confusion = @"75cb0e64";  //与服务器端预定的混淆md5生成的字符串

@implementation TDSecurity

+(NSString *)encrypMD5String:(NSString *)str {
    if (!str) return nil;
    
    //解决字符串中含有"\0"字符时，strlen长度不对的问题
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    const char *cStr = [data bytes];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)data.length, result);
    
    NSMutableString *md5Str = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
        [md5Str appendFormat:@"%02x", result[i]];
    }
    return md5Str;
}

+(NSString *)encrypMD5StringwithSalt:(NSString *)str{
    if (!str) return nil;
    return [self encrypMD5String:[str stringByAppendingString:TDMD5Salt]];
}

+(NSString *)encrypMD5StringwithConfusion:(NSString *)str{
    if (!str) return nil;
    NSString *md5 = [self encrypMD5String:str];
    NSString *reStr = [NSString stringWithFormat:@"%@%@%@",[md5 substringToIndex:TDMD5ConfusionIndex],TDMD5Confusion,[md5 substringFromIndex:TDMD5ConfusionIndex]];
    return reStr;
}

+(void)evaluateTouchIDWithReson:(NSString *)reason fallbackTitle:(NSString *)title Success:(void (^)(void))suc fail:(void (^)(NSInteger))fail{
    if (@available(iOS 8.0, *)) {
        LAContext *context = [[LAContext alloc] init];
        context.localizedFallbackTitle = title;
        NSError *error = nil;
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:reason reply:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    if(suc){
                        suc();
                    }
                }else if(error){
                    fail(error.code);
                }
            }];
        }else{
            if (fail) {
                fail(TDTouchIdNotSopport);
            }
        }
    }else{
        if (fail) {
            fail(TDTouchIdNotSopport);
        }
    }
}


+(void)evaluateTouchIDWithReson:(NSString *)reason fallbackTitle:(NSString *)title Success:(void (^)(void))suc failure:(void (^)(NSString *))fail{
    if (@available(iOS 8.0, *)) {
        LAContext *context = [[LAContext alloc] init];
        context.localizedFallbackTitle = title;
        NSError *error = nil;
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:reason reply:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    if(suc){
                        suc();
                    }
                }else if(error){
                    switch (error.code) {
                        case LAErrorAuthenticationFailed:
                            fail(@"TouchID 验证失败");
                            break;
                        case LAErrorUserCancel:
                            fail(@"TouchID 被用户手动取消");
                            break;
                        case LAErrorUserFallback:
                            fail(@"用户不使用TouchID,选择手动输入密码");
                            break;
                        case LAErrorSystemCancel:
                            fail(@"TouchID 被系统取消 (如遇到来电,锁屏,按了Home键等)");
                            break;
                        case LAErrorPasscodeNotSet:
                            fail(@"TouchID 无法启动,因为用户没有设置密码");
                            break;
                        case LAErrorTouchIDNotEnrolled:
                            fail(@"TouchID 无法启动,因为用户没有设置TouchID");
                            break;
                        case LAErrorTouchIDNotAvailable:
                            fail(@"TouchID 无效");
                            break;
                        case LAErrorTouchIDLockout:
                            fail(@"TouchID 被锁定(连续多次验证TouchID失败,系统需要用户手动输入密码)");
                            break;
                        case LAErrorAppCancel:
                            fail(@"当前软件被挂起并取消了授权 (如App进入了后台等)");
                            break;
                        case LAErrorInvalidContext:
                            fail(@"当前软件被挂起并取消了授权 (LAContext对象无效)");
                            break;
                        default:
                            break;
                    }
                }
            }];
        }else{
            if (fail) {
                fail(@"该设备不支持touchId");
            }
        }
    }else{
        if (fail) {
            fail(@"该设备不支持touchId");
        }
    }
}

+(BOOL)savePwdInKeyChain:(NSString *)password username:(NSString *)username {
    TDSecurity *security = [TDSecurity new];
    [security deleteItemByService:TDKeyChainService account:username];
    return [security addItemByPwd:password Service:TDKeyChainService account:username];
}
+(void)savePwdInKeyChainAsync:(NSString *)password username:(NSString *)username Success:(void (^)(void))suc fail:(void (^)(void))fail {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL status = [TDSecurity savePwdInKeyChain:password username:username];
        if (status && suc !=nil) {
            suc();
        }else if(fail != nil){
            fail();
        }
    });
}
+(NSString *)getPwdFromKeyChainByUsername:(NSString *)username {
    TDSecurity *security = [TDSecurity new];
    return [security findItemByService:TDKeyChainService account:username];
}
-(NSString *)findItemByService:(NSString *)service account:(NSString *)account{
    NSDictionary *query = @{
                            (id)kSecClass: (id)kSecClassGenericPassword,
                            (id)kSecAttrService:service,
                            (id)kSecAttrAccount:account,
                            (id)kSecReturnData: @YES,
                            (id)kSecUseOperationPrompt: @"请求查询密码的权限",
                            };
    CFTypeRef dataTypeRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
    if (status == errSecSuccess) {
        NSData *resultData = (__bridge_transfer NSData *)dataTypeRef;
        NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
        return result;
    }else {
        return nil;
    }
}

-(BOOL)updateItemByPwd:(NSString *)pwd Service:(NSString *)service account:(NSString *)account {
    NSDictionary *query = @{
                            (id)kSecClass: (id)kSecClassGenericPassword,
                            (id)kSecAttrService:service,
                            (id)kSecAttrAccount:account,
                            (id)kSecUseOperationPrompt: @"请求更新密码的权限"
                            };
    
    NSData *updatedSecretPasswordTextData = [pwd dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *changes = @{
                              (id)kSecValueData: updatedSecretPasswordTextData
                              };
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
    if (status == errSecSuccess) {
        return YES;
    }else {
        NSLog(@"update Item error, status:%d",(int)status);
        return NO;
    }
}
-(BOOL)addItemByPwd:(NSString *)pwd Service:(NSString *)service account:(NSString *)account {
    CFErrorRef error = NULL;
    /*
     kSecAccessControlUserPresence:item通过锁屏密码或者Touch ID进行验证，Touch ID可以不设置，增加或者移除手指都能使用item。
     kSecAccessControlTouchIDAny:item只能通过Touch ID验证，Touch ID 必须设置，增加或移除手指都能使用item。
     kSecAccessControlTouchIDCurrentSet:item只能通过Touch ID进行验证，增加或者移除手指，item将被删除。
     kSecAccessControlDevicePasscode:item通过锁屏密码验证访问。
     kSecAccessControlOr:如果设置多个flag，只要有一个满足就可以。
     kSecAccessControlAnd:如果设置多个flag，必须所有的都满足才行。
     kSecAccessControlPrivateKeyUsage:私钥签名操作
     kSecAccessControlApplicationPassword:额外的item密码，可以让用户自己设置一个访问密码，这样只有知道密码才能访问。
     */
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlTouchIDAny, &error);
    
    if (sacObject == NULL || error != NULL) {
        NSString *errorString = [NSString stringWithFormat:@"SecItemAdd can't create sacObject: %@", error];
        NSLog(@"%@",errorString);
        return NO;
    }
    
    NSDictionary *attributes = @{
                                 (id)kSecClass: (id)kSecClassGenericPassword,
                                 (id)kSecAttrService: service,
                                 (id)kSecAttrAccount:account,
                                 (id)kSecValueData: [pwd dataUsingEncoding:NSUTF8StringEncoding],
                                 (id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                 };
    
   OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
    if (status == errSecSuccess) {
        return YES;
    }else {
        NSLog(@"add Item error, status:%d",(int)status);
        return NO;
    }
}
-(void)deleteItemByService:(NSString *)service account:(NSString *)account {
    NSDictionary *query = @{
                            (id)kSecClass: (id)kSecClassGenericPassword,
                            (id)kSecAttrService:service,
                            (id)kSecAttrAccount:account
                            };
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (!status) {
        NSLog(@"delete item error,status:%d",(int)status);
    }
}
@end
