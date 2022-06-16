//
//  AgoraChatCallConfig.m
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/12/9.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "AgoraChatCallConfig.h"
#import "UIImage+Ext.h"

@implementation AgoraChatCallUser
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.nickName = @"";
    }
    return self;
}

+ (instancetype)userWithNickName:(NSString*)aNickName image:(NSURL*)aUrl
{
    AgoraChatCallUser *user = [[AgoraChatCallUser alloc] init];
    if (aNickName.length > 0) {
        user.nickName = aNickName;
    }
    if (aUrl && aUrl.absoluteString.length > 0) {
        user.headImage = aUrl;
    }
    return user;
}
@end

@interface AgoraChatCallConfig ()

@end

@implementation AgoraChatCallConfig

- (instancetype)init
{
    if(self = [super init]) {
        [self _initParams];
    }
    return self;
}

- (void)_initParams
{
    _callTimeOut = 30;
    _enableRTCTokenValidate = NO;
    _users = [NSMutableDictionary dictionary];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *ringFilePath = [bundle pathForResource:@"AgoraChatCallKit.bundle/music" ofType:@"mp3"];
    //_ringFileUrl = [[NSBundle mainBundle] URLForResource:@"music" withExtension:@".mp3"];
    _ringFileUrl = [NSURL fileURLWithPath:ringFilePath];
    _agoraAppId = @"15cb0d28b87b425ea613fc46f7c9f974";
}

- (AgoraVideoEncoderConfiguration*)encoderConfiguration
{
    if(!_encoderConfiguration) {
        _encoderConfiguration = [[AgoraVideoEncoderConfiguration alloc]
                                 initWithSize:AgoraVideoDimension640x360
                                 frameRate:AgoraVideoFrameRateFps15
                                 bitrate:AgoraVideoBitrateStandard
                                 orientationMode:AgoraVideoOutputOrientationModeAdaptative];
    }
    return _encoderConfiguration;
}

- (void)setUsers:(NSMutableDictionary<NSString *,AgoraChatCallUser *> *)users
{
    _users = [users mutableCopy];
    [NSNotificationCenter.defaultCenter postNotificationName:@"AgoraChatCallUserUpdated" object:nil];
}

- (void)setUser:(NSString*)aUser info:(AgoraChatCallUser*)aInfo
{
    if (aUser.length > 0 && aInfo) {
        [self.users setObject:aInfo forKey:aUser];
        [NSNotificationCenter.defaultCenter postNotificationName:@"AgoraChatCallUserUpdated" object:nil];
    }
}

@end
