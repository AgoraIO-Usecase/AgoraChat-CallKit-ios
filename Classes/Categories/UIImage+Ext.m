//
//  UIImage+Ext.m
//  EaseCallUI
//
//  Created by lixiaoming on 2020/12/11.
//

#import "UIImage+Ext.h"
#import "NSBundle+AgoraChatCallKit.h"

@implementation UIImage (Ext)

+ (UIImage *)agoraChatCallKit_imageNamed:(NSString *)imageName
{
    return [UIImage imageNamed:imageName inBundle:NSBundle.agoraChatCallKitBundle withConfiguration:nil];
}

@end
