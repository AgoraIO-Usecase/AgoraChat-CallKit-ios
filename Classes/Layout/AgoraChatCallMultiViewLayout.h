//
//  EaseCallMultiViewLayout.h
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/4/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AgoraChatCallMultiViewLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) BOOL isVideo;
@property (nonatomic, assign) NSInteger bigIndex;

@property (nonatomic, strong) BOOL(^getVideoEnableBlock)(NSIndexPath *indexPath);

@end

NS_ASSUME_NONNULL_END
