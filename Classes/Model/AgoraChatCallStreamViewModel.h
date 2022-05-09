//
//  EaseCallStreamViewModel.h
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/4/20.
//

@import Foundation;

#import "AgoraChatCallDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface AgoraChatCallStreamViewModel : NSObject

@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, strong) UIImage *showUserHeaderImage;
@property (nonatomic, strong) NSString *showUsername;
@property (nonatomic, strong) NSString *showStatusText;
@property (nonatomic, strong) NSURL *showUserHeaderURL;
@property (nonatomic, assign) AgoraChatCallType callType;
@property (nonatomic, assign) BOOL isMini;
@property (nonatomic, assign) BOOL joined;
@property (nonatomic, assign) BOOL enableVoice;
@property (nonatomic, assign) BOOL isTalking;
@property (nonatomic, assign) BOOL enableVideo;

@end

NS_ASSUME_NONNULL_END
