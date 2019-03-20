//
//  WaitingProgressBar.h
//  HudDemo
//
//  Created by tiandy on 15-1-22.
//
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@interface WaitingProgressBar : NSObject
+ (void)showProgressBar:(UIView *)view;
+ (void)showProgressBar:(UIView *)view backColor:(UIColor *)_bkColor forColor:(UIColor *)_forColor;
+ (void)showProgressBar:(UIView *)view showText:(NSString *)text;
+ (void)hideProgressBar:(UIView *)view;
+ (void)showProgressCircle:(UIView *)view;
+ (void)showProgressCircle:(UIView *)view showColor:(UIColor *)_color;
+ (void)hideProgressCircle:(UIView *)view;
@end
