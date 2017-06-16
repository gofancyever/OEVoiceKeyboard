//
//  GFVoiceToolBar.m
//  gf_testVoice
//
//  Created by gaof on 2017/6/15.
//  Copyright © 2017年 gaof. All rights reserved.
//

#import "GFVoiceToolBar.h"

@interface GFVoiceToolBar()
@property (nonatomic,copy) void(^block)(UIButton *sender);

@end

@implementation GFVoiceToolBar
-(instancetype)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 60);
        UIButton *voiceBtn = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-60, 0, 60, 60)];
        [voiceBtn setImage:[UIImage imageNamed:@"btn_xnd_yuyinshuru.png"] forState:UIControlStateNormal];
        [voiceBtn setImage:[UIImage imageNamed:@"btn_xnd_jianpanshufru.png"] forState:UIControlStateSelected];
        [voiceBtn addTarget:self action:@selector(switchDidClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:voiceBtn];
    }
    return self;
}
- (void)switchDidClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(voiceToolBarSwitchDidClick:)]) {
        [self.delegate voiceToolBarSwitchDidClick:sender];
    }
    
    if (self.block) {
        self.block(sender);
    }
}
- (void)switchClick:(void(^)(UIButton *sender))block {
    if (block) {
        self.block = block;
    }
}

//============单例================
//static id _instance;
//+(instancetype)allocWithZone:(struct _NSZone *)zone {
//    if (_instance == nil){
//        _instance = [super allocWithZone:zone];
//    }
//    return _instance;
//}
//
//
//- (instancetype) init {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        UIView *view = [super init];
//        view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 60);
//        UIButton *voiceBtn = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-60, 0, 60, 60)];
//        [voiceBtn setImage:[UIImage imageNamed:@"btn_xnd_yuyinshuru"] forState:UIControlStateNormal];
//        [voiceBtn setImage:[UIImage imageNamed:@"btn_xnd_jianpanshufru"] forState:UIControlStateSelected];
//        [voiceBtn addTarget:self action:@selector(switchDidClick:) forControlEvents:UIControlEventTouchUpInside];
//        [view addSubview:voiceBtn];
//        _instance = view;
//    });
//    return _instance;
//}
//
//+ (instancetype)copyWithZone:(struct _NSZone *)zone{
//    return _instance;
//}
//+(instancetype)mutableCopyWithZone:(struct _NSZone *)zone{
//    return _instance;
//}
//
//
//+ (instancetype)share {
//    return [[self alloc] init];
//}

@end
