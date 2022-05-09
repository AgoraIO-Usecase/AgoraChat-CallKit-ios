//
//  AgoraChatCallIncomingAlertView.h
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/4/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AgoraChatCallIncomingAlertView : UIView

- (instancetype)initWithTitle:(NSString *)title content:(NSString *)content tapHandle:(void(^)(void))tapHandle answerHandle:(void(^)(void))answerHandle hangupHandle:(void(^)(void))hangupHandle;

@end

@protocol IAgoraChatCallIncomingAlertViewShowable <NSObject>

@property (readonly) NSString *showAlertTitle;
@property (readonly) NSString *showAlertContent;

- (void)showAlert;
- (void)hideAlert;

@end

NS_ASSUME_NONNULL_END
