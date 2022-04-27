//
//  NSBundle+AgoraChatCallKit.m
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/4/27.
//

#import "NSBundle+AgoraChatCallKit.h"

static NSBundle *imageBundle;

@implementation NSBundle (AgoraChatCallKit)

+ (instancetype)agoraChatCallKitBundle
{
    if (!imageBundle) {
        NSString *path = [NSBundle.mainBundle pathForResource:@"AgoraChatCallKit" ofType:@"bundle"];
        imageBundle = [NSBundle bundleWithPath:path];
    }
    return imageBundle;
}

@end
