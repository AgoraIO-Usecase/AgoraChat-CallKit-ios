//
//  AgoraChatCallKitModel.h
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/6/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AgoraChatCallKitModelHandleType) {
    AgoraChatCallKitModelHandleTypeUnhandle,
    AgoraChatCallKitModelHandleTypeAccept,
    AgoraChatCallKitModelHandleTypeRefuse,
};

@interface AgoraChatCallKitModel : NSObject

@property (nonatomic, strong) NSString *unhandleCallId;
@property (nonatomic, assign) AgoraChatCallKitModelHandleType handleType;
@property (nonatomic, strong) dispatch_block_t timeoutBlock;

@end

NS_ASSUME_NONNULL_END
