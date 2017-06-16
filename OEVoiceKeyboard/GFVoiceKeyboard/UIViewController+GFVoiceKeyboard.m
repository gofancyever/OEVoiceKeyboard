
//
//  UIViewController+GFVoiceKeyboard.m
//  gf_testVoice
//
//  Created by gaof on 2017/6/16.
//  Copyright © 2017年 gaof. All rights reserved.
//

#import "UIViewController+GFVoiceKeyboard.h"
#import "UITextView+GFVoiceKeyboard.h"
#import "UITextField+GFVoiceKeyboard.h"
#import "GFVoiceToolBar.h"
#import <objc/runtime.h>

@implementation UIViewController (GFVoiceKeyboard)
-(void)setEnableVoiceKeyboard:(BOOL)enableVoiceKeyboard{
    if (enableVoiceKeyboard) {
        [self registerNoti];
        [self removeNotiMethod];
    }else{
        [self removeToolbarIfRequired];
    }
}




//不可再分类中重写dealloc 方法  不会调用super dealloc 方法 导致键盘没有被释放 应在子类中重写dealloc 方法释放通知
//https://stackoverflow.com/questions/33541122/ios9-keyboard-crash-on-dismiss
//动态添加方法 用于释放通知
- (void)removeNotiMethod {
    
    Class class = [self class];
    SEL originalSelector = @selector(viewDidDisappear:);
    SEL swizzledSelector = @selector(GF_viewDidDisappear:);
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}
- (void)GF_viewDidDisappear:(BOOL)animated {
    [self GF_viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
}

//-(void)dealloc
//{
//
//    //Removing notification observers on dealloc.
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}
-(void)registerNoti {
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldViewDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldViewDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];

    

}
-(void)textFieldViewDidBeginEditing:(NSNotification*)notification{
    //  Getting object
    UIView *textFieldView = notification.object;
    if (textFieldView.inputAccessoryView == nil) {
        [self addToolbarIfRequired:textFieldView];
    }else{
        [textFieldView reloadInputViews];
    }
    
}

-(void)addToolbarIfRequired:(UIView *)textFieldView {
    if ([textFieldView respondsToSelector:@selector(setInputAccessoryView:)]) {
        if ([textFieldView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)textFieldView;
            textField.enableVoiceKeyboard = YES;
        }
        else if ([textFieldView isKindOfClass:[UITextView class]]){
            UITextView *textView = (UITextView *)textFieldView;
            textView.enableVoiceKeyboard = YES;
        }
        [textFieldView reloadInputViews];
        
    }
}


-(void)removeToolbarIfRequired
{
    
    //	Getting all the sibling textFields.
    NSArray *siblings = [self responderSiblings];
    
    for (UITextField *textField in siblings)
    {
        UIView *toolbar = [textField inputAccessoryView];
        if ([textField respondsToSelector:@selector(setInputAccessoryView:)] &&
            ([toolbar isKindOfClass:[GFVoiceToolBar class]]))
        {
            textField.inputAccessoryView = nil;
        }
    }
}

- (NSArray*)responderSiblings
{
    
    NSArray *siblings = self.view.subviews;

    NSMutableArray *tempTextFields = [[NSMutableArray alloc] init];
    
    for (UIView *textField in siblings)
        if ([self _IQcanBecomeFirstResponder:textField]){
            [tempTextFields addObject:textField];
        }
    
    
    return tempTextFields;
}

-(BOOL)_IQcanBecomeFirstResponder:(UIView *)view
{
    BOOL _IQcanBecomeFirstResponder = NO;
    
    if ([self isKindOfClass:[UITextField class]])
    {
        _IQcanBecomeFirstResponder = [(UITextField*)self isEnabled];
    }
    else if ([self isKindOfClass:[UITextView class]])
    {
        _IQcanBecomeFirstResponder = [(UITextView*)self isEditable];
    }
    
    if (_IQcanBecomeFirstResponder == YES)
    {
        _IQcanBecomeFirstResponder = ([view isUserInteractionEnabled] && ![view isHidden] && [view alpha]!=0.0);
    }
    
    return _IQcanBecomeFirstResponder;
}


@end
