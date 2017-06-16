//
//  GFVoiceToolBar.h
//  gf_testVoice
//
//  Created by gaof on 2017/6/15.
//  Copyright © 2017年 gaof. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GFVoiceToolBarDelegate <NSObject>
@optional
- (void)voiceToolBarSwitchDidClick:(UIButton *)sender;

@end
@interface GFVoiceToolBar : UIView
@property (nonatomic,weak) id<GFVoiceToolBarDelegate> delegate;
//+(instancetype)share;
- (void)switchClick:(void(^)(UIButton *sender))block;


@end
