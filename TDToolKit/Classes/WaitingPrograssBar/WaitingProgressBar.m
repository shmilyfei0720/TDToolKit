//
//  WaitingProgressBar.m
//  HudDemo
//
//  Created by tiandy on 15-1-22.
//
//

#import "WaitingProgressBar.h"
#import <Masonry/Masonry.h>

@implementation WaitingProgressBar

+ (void)showProgressBar:(UIView *)view {
    //阻塞住所有使用self.navigationController.view
    //显示之前，如果这个view上已经存在了，则先隐藏掉。
    [MBProgressHUD hideHUDForView:view animated:NO];
    [MBProgressHUD showHUDAddedTo:view animated:YES];
}

+ (void)showProgressBar:(UIView *)view backColor:(UIColor *)_bkColor forColor:(UIColor *)_forColor {
    [self hideProgressBar:view];
}

+ (void)hideProgressBar:(UIView *)view {
    [MBProgressHUD hideHUDForView:view animated:YES];
}

+ (void)showProgressBar:(UIView *)view showText:(NSString *)text {
    [MBProgressHUD hideHUDForView:view animated:NO];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    //hud.mode = MBProgressHUDModeText;
    hud.labelText = text;
    /**
    hud.margin = 10.f;
    hud.yOffset = 150.f;
    hud.removeFromSuperViewOnHide = YES;
     **/
}

+ (void)showProgressCircle:(UIView *)view {
    UIActivityIndicatorView *pPlayAivView = [[UIActivityIndicatorView alloc] init];
    
    if (pPlayAivView == nil) {
        return;
    }
    
    [view addSubview:pPlayAivView];
    [pPlayAivView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(view);
    }];
 
    pPlayAivView.hidden = NO;
    [pPlayAivView startAnimating];
}

+ (void)showProgressCircle:(UIView *)view showColor:(UIColor *)_color {
    UIActivityIndicatorView *pPlayAivView = [[UIActivityIndicatorView alloc] init];
    
    if (pPlayAivView == nil) {
        return;
    }
    [pPlayAivView setColor:_color];
    
    [view addSubview:pPlayAivView];
    [pPlayAivView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(view);
    }];
    
    pPlayAivView.hidden = NO;
    [pPlayAivView startAnimating];
}

+ (void)hideProgressCircle:(UIView *)view {
    UIActivityIndicatorView *pPlayAivView = nil;
    NSEnumerator *subviewsEnum = [view.subviews reverseObjectEnumerator];
    for (UIView *subview in subviewsEnum) {
        if (subview == nil) {
            continue;
        }
        
        if (![subview isKindOfClass:[UIActivityIndicatorView class]]) {
            continue;
        }
            
        pPlayAivView = (UIActivityIndicatorView *)subview;
        if (pPlayAivView == nil) {
            continue;
        }
        [pPlayAivView removeFromSuperview];
        pPlayAivView.hidden = YES;
    }
}

@end
