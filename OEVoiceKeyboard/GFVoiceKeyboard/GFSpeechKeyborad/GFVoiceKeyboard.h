//
//  GFVoiceKeyboard.h
//  gf_testVoice
//
//  Created by gaof on 2017/4/7.
//  Copyright © 2017年 gaof. All rights reserved.
//



#import <UIKit/UIKit.h>

@protocol GFVoiceKeyboardDelegate <NSObject>

@optional
- (void)voiceKeyboardDidRecognitionResult:(NSString *)result;
- (void)voiceKeyboardDidDismiss;
- (void)voiceKeyboardTextViewDidBeginEditing:(UITextView *)textView;

@end

@interface GFVoiceKeyboard : UIView


- (void)keyboardRecognition:(void (^)(NSString *result))block;
- (void)keyboardDismiss:(void(^)())block;

@property (nonatomic,weak) id<GFVoiceKeyboardDelegate> delegate;

@end
