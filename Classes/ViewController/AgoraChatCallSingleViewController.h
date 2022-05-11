//
//  EaseCallSingleViewController.h
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "AgoraChatCallBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AgoraChatCallSingleViewController : AgoraChatCallBaseViewController

@property (nonatomic) BOOL isCaller;
@property (nonatomic, copy) NSString *remoteUserAccount;

- (instancetype)initWithisCaller:(BOOL)aIsCaller type:(AgoraChatCallType)aType  remoteName:(NSString*)aRemoteName;
- (void)setRemoteMute:(BOOL)aMuted;
- (void)setRemoteEnableVideo:(BOOL)aEnabled;
- (void)setLocalDisplayView:(UIView*)aDisplayView enableVideo:(BOOL)aEnableVideo;
- (void)setRemoteDisplayView:(UIView*)aDisplayView enableVideo:(BOOL)aEnableVideo;

@end

NS_ASSUME_NONNULL_END
