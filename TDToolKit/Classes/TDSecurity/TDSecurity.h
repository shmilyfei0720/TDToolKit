//
//  TDSecurity.h
//  Pods
//
//  Created by tiandy on 2019/1/26.
//

#import <Foundation/Foundation.h>
#import <LocalAuthentication/LAError.h>


static NSInteger const  TDTouchIdNotSopport = -1 ;  //设备不支持touchid
static NSString * const TDKeyChainService = @"SampleService";  //服务标志

@interface TDSecurity : NSObject

/**
 计算字符串md5值
 @param str 待加密字符串
 @return md5值
 */
+(NSString *)encrypMD5String:(NSString *)str;


/**
 计算字符串加盐后的md5值

 @param str 待加密字符串
 @return 加盐加密的md5值
 */
+(NSString *)encrypMD5StringwithSalt:(NSString *)str;


/**
 计算字符串md5值,加入随机信息混淆

 @param str 待加密字符串
 @return 混淆后的md5值
 */
+(NSString *)encrypMD5StringwithConfusion:(NSString *)str;


/**
 本地touchID验证
 
 @param reason 认证原因(显示在弹窗)
 @param title 用密码登录的按钮标题(认证失败一次后显示)
 @param suc 认证成功
 @param fail 认证失败
 */
+(void)evaluateTouchIDWithReson:(NSString *)reason fallbackTitle:(NSString *)title Success:(void(^)(void))suc fail:(void(^)(NSInteger errcode))fail;


/**
 本地touchID验证
 
 @param reason 认证原因(显示在弹窗)
 @param title 用密码登录的按钮标题(认证失败一次后显示)
 @param suc 认证成功
 @param fail 认证失败
 */
+(void)evaluateTouchIDWithReson:(NSString *)reason fallbackTitle:(NSString *)title Success:(void(^)(void))suc failure:(void(^)(NSString *errString))fail;

/**
 保存密码到钥匙串

 @param password 密码
 @param username 用户名
 @return 操作是否成功
 */
+(BOOL)savePwdInKeyChain:(NSString *)password username:(NSString *)username;

/**
 异步保存密码到钥匙串

 @param password 密码
 @param username 用户名
 @param suc 保存成功
 @param fail 保存失败
 */
+(void)savePwdInKeyChainAsync:(NSString *)password username:(NSString *)username Success:(void(^)(void))suc fail:(void(^)(void))fail;

/**
 从钥匙串中获取密码

 @param username 用户名
 @return NSString 钥匙串中的密码
 */
+(NSString *)getPwdFromKeyChainByUsername:(NSString *)username;

@end

