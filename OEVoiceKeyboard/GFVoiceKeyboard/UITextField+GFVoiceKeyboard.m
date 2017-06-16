//
//  UITextField+GFVoiceKeyboard.m
//  gf_testVoice
//
//  Created by gaof on 2017/6/15.
//  Copyright © 2017年 gaof. All rights reserved.
//

#import "UITextField+GFVoiceKeyboard.h"
#import "GFVoiceKeyboard.h"
#import "GFVoiceToolBar.h"

@interface UITextField()<GFVoiceKeyboardDelegate,GFVoiceToolBarDelegate>

@end

IB_DESIGNABLE
@implementation UITextField (GFVoiceKeyboard)



-(void)setEnableVoiceKeyboard:(BOOL)enableVoiceKeyboard{
    if (enableVoiceKeyboard) {
        GFVoiceToolBar *bar = [[GFVoiceToolBar alloc] init];
        bar.delegate = self;
        [self setInputAccessoryView:bar];
    }else{
         [self setInputAccessoryView:nil];

    }
}
-(BOOL)enableVoiceKeyboard {
    return [self.inputView isKindOfClass:[GFVoiceKeyboard class]];
}


// 切换键盘
-(void)switchKeyboard:(BOOL)isVoiceKeyboard;
{

    if (isVoiceKeyboard) {
        GFVoiceKeyboard *keyboard = [[GFVoiceKeyboard alloc] init];
        keyboard.delegate = self;
        [self setInputView:keyboard];
    }else{
        [self setInputView:nil];
    }
    

    [self reloadInputViews];
    
}

#pragma mark - GFVoiceToolBarDelegate
-(void)voiceToolBarSwitchDidClick:(UIButton *)sender {
    [self switchKeyboard:sender.selected];
}


#pragma mark - GFVoiceKeyboardDelegate
-(void)voiceKeyboardDidDismiss {
    [self resignFirstResponder];
}
-(void)voiceKeyboardDidRecognitionResult:(NSString *)result {
    self.text = [NSString stringWithFormat:@"%@%@",self.text,result];
}

@end
