//
//  UIImage+Ext.m
//  EaseCallUI
//
//  Created by lixiaoming on 2020/12/11.
//

#import "UIImage+Ext.h"
#import "EaseCallStreamView.h"

static NSBundle *imageBundle;

@implementation UIImage (Ext)

+ (UIImage *)agoraChatCallKit_imageNamed:(NSString *)imageName
{
    if (!imageBundle) {
        NSString *path = [NSBundle.mainBundle pathForResource:@"AgoraChatCallKit" ofType:@"bundle"];
        imageBundle = [NSBundle bundleWithPath:path];
    }
    return [UIImage imageNamed:imageName inBundle:imageBundle withConfiguration:nil];
}

@end
