//
//  UIWindow+AgoraChatCallKit.m
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/6/14.
//

#import "UIWindow+AgoraChatCallKit.h"

@implementation UIWindow (AgoraChatCallKit)

+ (UIWindow *)agoraChatCallKit_keyWindow
{
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
            for (UIWindow *window in scene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    } else {
        return [UIApplication sharedApplication].keyWindow;
    }
    return nil;
}

@end
