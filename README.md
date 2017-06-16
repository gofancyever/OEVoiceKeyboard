#OEVoiceKeyboard

基于科大讯飞语音识别键盘

![](https://github.com/ofEver/OEVoiceKeyboard/blob/master/screenshot/example.gif)
####示例:

导入头文件：

<pre>
#import "UITextField+GFVoiceKeyboard.h"
#import "UITextView+GFVoiceKeyboard.h"
#import "UIViewController+GFVoiceKeyboard.h"
</pre>
controllerView 全局开启语音键盘：
<pre>
UIViewController *viewController = [[UIViewController alloc] init];
viewController.enableVoiceKeyboard = YES;
</pre>
为指定textField 或 textView 开启
<pre>
UITextField *textField = [[UITextField alloc] init];
textField.enableVoiceKeyboard = YES;
</pre>
支持 storyboard 设置

![alt](https://github.com/ofEver/OEVoiceKeyboard/blob/master/screenshot/set.png)
##注意：
基于科大讯飞SDK使用请设置正确的Appid并导入相应.framework





